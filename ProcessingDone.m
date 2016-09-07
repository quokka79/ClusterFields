function ProcessingDone(UserEmail,Subject,Body)

% Replace the phrase below with your own phrase.
% Make sure the quotes are kept!;
C = '4e65726127674c62684e507972697265507576707872613f';

% Replace the username below with your own UoM username
U = 'mdehsdwk';

setpref('Internet','E_mail',UserEmail);
setpref('Internet','SMTP_Server','outgoing.manchester.ac.uk');
setpref('Internet','SMTP_Username',U);
setpref('Internet','SMTP_Password',d(char(sscanf(C,'%2X').')));

props = java.lang.System.getProperties;
props.setProperty('mail.smtp.auth','true');
props.setProperty('mail.smtp.socketFactory.class', 'javax.net.ssl.SSLSocketFactory');
props.setProperty('mail.smtp.socketFactory.port','587');

sendmail(UserEmail, Subject, Body);
end
