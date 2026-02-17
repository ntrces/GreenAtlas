// Setup type definitions for built-in Supabase Runtime APIs
import "@supabase/functions-js/edge-runtime.d.ts"
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

serve(async (req) => {
  // Webhooks send the 'record' (new data) and 'old_record' (before update)
  const { record, old_record } = await req.json()
  
  // 1. Initialize Supabase with Service Role Key (bypasses RLS for admin tasks)
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  )

  // 2. Fetch User Preferences from the 'profiles' table
  const { data: profile, error } = await supabase
    .from('profiles')
    .select('email, push_notifications_enabled, email_notifications_enabled, fcm_token')
    .eq('id', record.user_id)
    .single()

  if (error || !profile) {
    return new Response(JSON.stringify({ error: 'User profile not found' }), { status: 404 })
  }

  const results = []

  // 3. Logic: Send EMAIL if enabled and status has changed
  if (profile.email_notifications_enabled && record.status !== old_record?.status) {
    const resendApiKey = Deno.env.get('RESEND_API_KEY')
    if (resendApiKey) {
      await fetch('https://api.resend.com/emails', {
        method: 'POST',
        headers: { 
          'Authorization': `Bearer ${resendApiKey}`, 
          'Content-Type': 'application/json' 
        },
        body: JSON.stringify({
          from: 'GreenAtlas <updates@greenatlas.com>',
          to: profile.email,
          subject: `Update: ${record.incident_type} Report`,
          html: `<p>Your report status is now <strong>${record.status}</strong>.</p>`
        })
      })
      results.push('Email notification triggered')
    }
  }

  // 4. Logic: Send PUSH if enabled and token exists
  if (profile.push_notifications_enabled && profile.fcm_token) {
    const fcmKey = Deno.env.get('FIREBASE_SERVER_KEY')
    if (fcmKey) {
      await fetch('https://fcm.googleapis.com/fcm/send', {
        method: 'POST',
        headers: { 
          'Authorization': `key=${fcmKey}`, 
          'Content-Type': 'application/json' 
        },
        body: JSON.stringify({
          to: profile.fcm_token,
          notification: {
            title: "GreenAtlas Update",
            body: `Your report for ${record.incident_type} is now ${record.status}.`,
            sound: "default"
          }
        })
      })
      results.push('Push notification triggered')
    }
  }

  return new Response(
    JSON.stringify({ success: true, actions: results }),
    { headers: { "Content-Type": "application/json" } }
  )
})