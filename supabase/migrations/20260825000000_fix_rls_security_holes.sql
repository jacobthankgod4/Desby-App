-- Fix apprentice_tasks: restrict to participants only
DROP POLICY IF EXISTS "Participants can manage tasks" ON public.apprentice_tasks;
CREATE POLICY "Participants can manage tasks" ON public.apprentice_tasks
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.apprenticeships a
      WHERE a.id = apprenticeship_id
      AND (a.tailor_id::text = auth.uid()::text OR a.apprentice_id::text = auth.uid()::text)
    )
  );

-- Fix messages: restrict to conversation participants only
DROP POLICY IF EXISTS "Participants can view messages" ON public.messages;
CREATE POLICY "Participants can view messages" ON public.messages
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.conversations c
      WHERE c.id = conversation_id
      AND auth.uid()::text = ANY(c.participant_ids::text[])
    )
  );

-- Add INSERT policy for messages (senders can insert)
DROP POLICY IF EXISTS "Users can send messages" ON public.messages;
CREATE POLICY "Users can send messages" ON public.messages
  FOR INSERT WITH CHECK (
    auth.uid()::text = sender_id::text
  );
