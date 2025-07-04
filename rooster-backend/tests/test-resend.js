const { Resend } = require('resend');
const resend = new Resend('re_LgZPFSJv_JwEz9x7LU1V1xqG97iRtCTht'); // <-- paste your key here

async function main() {
  try {
    const result = await resend.emails.send({
      from: 'onboarding@resend.dev',
      to: 'ajaya@snstechservices.com.au', // <-- use your real email
      subject: 'Test from Resend',
      html: '<p>This is a test email sent directly using Resend API.</p>',
    });
    console.log(result);
  } catch (err) {
    console.error('Resend error:', err);
  }
}

main();
