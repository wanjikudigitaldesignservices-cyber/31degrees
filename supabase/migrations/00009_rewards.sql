-- Migration: 00009_rewards
-- Purpose: Rewards members and append-only ledger

CREATE TABLE public.rewards_members (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  card_no     text NOT NULL UNIQUE, -- generated on enrol, e.g. 31R-XXXXXX
  tier        rewards_tier NOT NULL DEFAULT 'bronze',
  enrolled_at timestamptz NOT NULL DEFAULT now(),
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_rewards_members_user ON public.rewards_members(user_id);
CREATE INDEX idx_rewards_members_card ON public.rewards_members(card_no);

CREATE TRIGGER rewards_members_updated_at
  BEFORE UPDATE ON public.rewards_members
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Append-only rewards ledger (balance derived from SUM)
CREATE TABLE public.rewards_ledger (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  member_id   uuid NOT NULL REFERENCES public.rewards_members(id) ON DELETE RESTRICT,
  entry_type  ledger_entry_type NOT NULL,
  points      int NOT NULL,  -- positive for earn/adjustment, negative for redeem/expire
  description text NOT NULL,
  order_id    uuid REFERENCES public.orders(id) ON DELETE SET NULL,
  adjusted_by uuid REFERENCES auth.users(id) ON DELETE SET NULL, -- for manual adjustments
  reason      text, -- required for manual adjustments
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_rewards_ledger_member ON public.rewards_ledger(member_id);
CREATE INDEX idx_rewards_ledger_order ON public.rewards_ledger(order_id);

-- View: current balance per member
CREATE OR REPLACE VIEW public.rewards_balances AS
SELECT
  rm.id AS member_id,
  rm.user_id,
  rm.card_no,
  rm.tier,
  COALESCE(SUM(rl.points), 0) AS balance
FROM public.rewards_members rm
LEFT JOIN public.rewards_ledger rl ON rl.member_id = rm.id
GROUP BY rm.id, rm.user_id, rm.card_no, rm.tier;
