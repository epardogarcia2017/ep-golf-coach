const webpush = require('web-push');

webpush.setVapidDetails(
  'mailto:' + process.env.ADMIN_EMAIL,
  process.env.VAPID_PUBLIC_KEY,
  process.env.VAPID_PRIVATE_KEY
);

export default async function handler(req, res) {
  if (req.method !== 'POST') return res.status(405).end();
  
  const { subscription, title, body, tag } = req.body;
  
  if (!subscription) return res.status(400).json({ error: 'No subscription' });
  
  try {
    await webpush.sendNotification(
      subscription,
      JSON.stringify({ title, body, tag: tag || 'ep-golf' })
    );
    res.status(200).json({ ok: true });
  } catch (err) {
    console.error('Push error:', err);
    res.status(500).json({ error: err.message });
  }
}
