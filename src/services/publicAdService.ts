import { supabase } from '@/src/lib/supabase';
import { Ad } from '@/src/types';

export const publicAdService = {
  async getActiveAds(placement: 'feed' | 'sidebar' | 'interstitial' = 'feed'): Promise<Ad[]> {
    try {
      const { data, error } = await supabase
        .from('ads')
        .select('*')
        .eq('status', 'active')
        .eq('placement', placement)
        .lte('starts_at', new Date().toISOString())
        .or(`ends_at.is.null,ends_at.gte."${new Date().toISOString()}"`)
        .order('created_at', { ascending: false });

      if (error) {
        // Log the error but don't break the app
        console.warn('Error fetching ads (this is normal if schema is not yet updated):', error.message);
        return [];
      }
      return data || [];
    } catch (err) {
      console.warn('Unexpected error in ad service:', err);
      return [];
    }
  },

  async trackImpression(adId: string) {
    const { error } = await supabase.rpc('increment_ad_metric', { 
      ad_id: adId, 
      metric_type: 'impression' 
    });
    if (error) console.error('Error tracking ad impression:', error);
  },

  async trackClick(adId: string) {
    const { error } = await supabase.rpc('increment_ad_metric', { 
      ad_id: adId, 
      metric_type: 'click' 
    });
    if (error) console.error('Error tracking ad click:', error);
  }
};
