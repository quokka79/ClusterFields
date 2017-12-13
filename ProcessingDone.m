function ProcessingDone(UserEmail,Subject,Body)

% Obviously do not use this if it contravenes your institution's security policy.
% Also obviously don't share this file around without removing your details from it first.

% Replace the username below with your own username
U = 'youremailusername';

% Replace the phrase below with your own phrase.
P = 'Password123';

setpref('Internet','E_mail',UserEmail);
setpref('Internet','SMTP_Server','outgoing.server.com');
setpref('Internet','SMTP_Username',U);
setpref('Internet','SMTP_Password',P);

props = java.lang.System.getProperties;
props.setProperty('mail.smtp.auth','true');
props.setProperty('mail.smtp.socketFactory.class', 'javax.net.ssl.SSLSocketFactory');
props.setProperty('mail.smtp.socketFactory.port','587');

sendmail(UserEmail, Subject, Body);
end
