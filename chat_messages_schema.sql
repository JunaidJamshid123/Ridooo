-- ============================================================================
-- CHAT MESSAGES TABLE - Add to Supabase
-- ============================================================================
-- Run this script in Supabase SQL Editor to add chat functionality
-- ============================================================================

-- Create chat_messages table
CREATE TABLE IF NOT EXISTS chat_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ride_id UUID REFERENCES rides(id) NOT NULL,
    sender_id UUID REFERENCES users(id) NOT NULL,
    receiver_id UUID REFERENCES users(id) NOT NULL,
    message_type TEXT NOT NULL DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'location', 'audio')),
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_chat_messages_ride_id ON chat_messages(ride_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_sender_id ON chat_messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_receiver_id ON chat_messages(receiver_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_created_at ON chat_messages(created_at DESC);

-- Enable Row Level Security
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DROP POLICY IF EXISTS "Users can view their own messages" ON chat_messages;
CREATE POLICY "Users can view their own messages" ON chat_messages
    FOR SELECT USING (
        auth.uid() = sender_id OR auth.uid() = receiver_id
    );

DROP POLICY IF EXISTS "Users can send messages" ON chat_messages;
CREATE POLICY "Users can send messages" ON chat_messages
    FOR INSERT WITH CHECK (
        auth.uid() = sender_id
    );

DROP POLICY IF EXISTS "Users can update read status of received messages" ON chat_messages;
CREATE POLICY "Users can update read status of received messages" ON chat_messages
    FOR UPDATE USING (
        auth.uid() = receiver_id
    );

-- Enable realtime for chat_messages table
ALTER PUBLICATION supabase_realtime ADD TABLE chat_messages;

-- ============================================================================
-- CONVERSATIONS VIEW - For easier querying
-- ============================================================================

CREATE OR REPLACE VIEW chat_conversations AS
SELECT DISTINCT ON (ride_id, LEAST(sender_id, receiver_id), GREATEST(sender_id, receiver_id))
    ride_id,
    CASE 
        WHEN sender_id < receiver_id THEN sender_id 
        ELSE receiver_id 
    END as user1_id,
    CASE 
        WHEN sender_id < receiver_id THEN receiver_id 
        ELSE sender_id 
    END as user2_id,
    (SELECT content FROM chat_messages cm2 
     WHERE cm2.ride_id = chat_messages.ride_id 
     ORDER BY cm2.created_at DESC LIMIT 1) as last_message,
    (SELECT created_at FROM chat_messages cm2 
     WHERE cm2.ride_id = chat_messages.ride_id 
     ORDER BY cm2.created_at DESC LIMIT 1) as last_message_at,
    (SELECT COUNT(*) FROM chat_messages cm2 
     WHERE cm2.ride_id = chat_messages.ride_id 
     AND cm2.is_read = false 
     AND cm2.receiver_id = auth.uid()) as unread_count
FROM chat_messages
ORDER BY ride_id, LEAST(sender_id, receiver_id), GREATEST(sender_id, receiver_id), created_at DESC;
