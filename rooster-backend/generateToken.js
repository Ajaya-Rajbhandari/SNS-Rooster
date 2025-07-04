const { Resend } = require('resend');

const resend = new Resend('re_LgZPFSJv_JwEz9x7LU1V1xqG97iRtCTht');

resend.emails.send({
  from: 'onboarding@resend.dev',
  to: 'ajaya@snstechservices.com.au',
  subject: 'Hello World',
  html: '<p>Congrats on sending your <strong>first email</strong>!</p>'
});