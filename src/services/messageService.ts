import { supabase } from '@/src/lib/supabase';
import { Message, Conversation } from '@/src/types';
import { notificationService } from './notificationService';

export const messageService = {
  async fetchMessages(currentUserId: string, targetUserId: string, page = 0, limit = 50) {
    const from = page * limit;
    const to = from + limit - 1;

    const { data, error } = await supabase
      .from('messages')
      .select('*')
      .or(`and(sender_id.eq.${currentUserId},receiver_id.eq.${targetUserId},deleted_by_sender.eq.false),and(sender_id.eq.${targetUserId},receiver_id.eq.${currentUserId},deleted_by_receiver.eq.false)`)
      .order('created_at', { ascending: false })
      .range(from, to);

    if (error) throw error;
    
    // Return in chronological order for the UI
    return (data as Message[]).reverse();
  },

  async fetchConversations(userId: string): Promise<Conversation[]> {
    // Use RPC for maximum scalability and performance
    const { data, error } = await supabase.rpc('get_user_conversations', { p_user_id: userId });

    if (error) throw error;

    return (data as any[]).map(conv => ({
      userId: conv.other_user_id,
      lastMessage: conv.last_message,
      timestamp: conv.last_message_at,
      unreadCount: Number(conv.unread_count),
      profile: conv.profile
    }));
  },

  async clearChat(userId: string, targetUserId: string) {
    // 1. Mark all current messages as deleted for the user
    await this.markMessagesAsDeleted(userId, targetUserId);

    // 2. Ensure the chat remains visible in the sidebar
    const { error } = await supabase
      .from('user_chats')
      .upsert({ 
        user_id: userId, 
        target_user_id: targetUserId, 
        is_hidden: false,
        last_cleared_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      });

    if (error) throw error;
  },

  async deleteChat(userId: string, targetUserId: string) {
    // 1. Mark all current messages as deleted for the user
    await this.markMessagesAsDeleted(userId, targetUserId);

    // 2. Hide the chat from the sidebar
    const { error } = await supabase
      .from('user_chats')
      .upsert({ 
        user_id: userId, 
        target_user_id: targetUserId, 
        is_hidden: true,
        updated_at: new Date().toISOString()
      });

    if (error) throw error;
  },

  async markMessagesAsDeleted(userId: string, targetUserId: string) {
    // Mark messages sent by user as deleted_by_sender
    await supabase
      .from('messages')
      .update({ deleted_by_sender: true })
      .match({ sender_id: userId, receiver_id: targetUserId });

    // Mark messages received by user as deleted_by_receiver
    await supabase
      .from('messages')
      .update({ deleted_by_receiver: true })
      .match({ receiver_id: userId, sender_id: targetUserId });
  },

  async sendMessage(senderId: string, receiverId: string, content: string, senderName: string, file?: File) {
    let mediaUrl = null;

    if (file) {
      const fileExt = file.name.split('.').pop();
      const fileName = `${senderId}/chat/${Math.random().toString(36).substring(2)}_${Date.now()}.${fileExt}`;
      
      const { error: uploadError } = await supabase.storage
        .from('media')
        .upload(fileName, file);

      if (uploadError) throw uploadError;

      const { data: { publicUrl } } = supabase.storage
        .from('media')
        .getPublicUrl(fileName);

      mediaUrl = publicUrl;
    }

    let finalContent = content.trim();
    if (mediaUrl) {
      try {
        // If content is already JSON (like a postRef), merge mediaUrl into it
        const parsed = JSON.parse(finalContent);
        if (typeof parsed === 'object' && parsed !== null) {
          parsed.mediaUrl = mediaUrl;
          finalContent = JSON.stringify(parsed);
        } else {
          finalContent = JSON.stringify({ text: finalContent, mediaUrl });
        }
      } catch (e) {
        // Not JSON, create new JSON
        finalContent = JSON.stringify({ text: finalContent, mediaUrl });
      }
    }

    const { data, error } = await supabase.from('messages').insert({
      sender_id: senderId,
      receiver_id: receiverId,
      content: finalContent,
    }).select().single();

    if (error) throw error;

    // Ensure chat is visible for both users when a new message is sent
    await supabase.from('user_chats').upsert([
      { user_id: senderId, target_user_id: receiverId, is_hidden: false, updated_at: new Date().toISOString() },
      { user_id: receiverId, target_user_id: senderId, is_hidden: false, updated_at: new Date().toISOString() }
    ]);

    // Create notification for receiver
    try {
      await notificationService.createNotification({
        user_id: receiverId,
        sender_id: senderId,
        type: 'message',
        title: `Mensaje de ${senderName}`,
        content: content.trim() || (mediaUrl ? 'Te envió un archivo' : 'Nuevo mensaje'),
        link: `/messages?to=${senderId}`
      });
    } catch (notifError) {
      console.error('Error creating notification:', notifError);
    }

    return data as Message;
  },

  async markAsRead(userId: string, senderId: string) {
    try {
      const { error } = await supabase
        .from('messages')
        .update({ 
          is_read: true,
          read_at: new Date().toISOString(),
          is_delivered: true,
          delivered_at: new Date().toISOString()
        })
        .match({ receiver_id: userId, sender_id: senderId, is_read: false });

      if (error) {
        // If the error is about missing columns, log a specific warning
        if (error.code === '42703') {
          console.warn('⚠️ Las columnas is_read o read_at no existen en la tabla messages. Por favor, ejecuta el script SQL proporcionado.');
        } else {
          throw error;
        }
      }
    } catch (err) {
      console.error('Error marking messages as read:', err);
    }
  },

  async markAsDelivered(userId: string, senderId: string) {
    try {
      const { error } = await supabase
        .from('messages')
        .update({ 
          is_delivered: true,
          delivered_at: new Date().toISOString()
        })
        .match({ receiver_id: userId, sender_id: senderId, is_delivered: false });

      if (error && error.code !== '42703') {
        throw error;
      }
    } catch (err) {
      console.error('Error marking messages as delivered:', err);
    }
  }
};
