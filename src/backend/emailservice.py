import resend
from typing import Dict
from fastapi import FastAPI, Body
import requests
from dotenv import load_dotenv
import os
import secrets

load_dotenv()

resend.api_key = os.getenv("RESEND_API_KEY")


app = FastAPI()

@app.post("/")
def send_mail(email: Dict[str, str] = Body(...)) -> Dict:
    verification_number = secrets.randbelow(9000) + 1000
    
    recipient_email = email.get("email")
    
    if not recipient_email:
        return {"error": "Email is required"}

    html_content = f"""<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html dir="ltr" lang="en">

  <head>
    <meta content="text/html; charset=UTF-8" http-equiv="Content-Type" />
    <meta name="x-apple-disable-message-reformatting" /><!--$-->
  </head>
  </div>

  <body style="background-color:#ffffff;font-family:HelveticaNeue,Helvetica,Arial,sans-serif;text-align:center">
    <table align="center" width="100%" border="0" cellPadding="0" cellSpacing="0" role="presentation" style="max-width:100%;background-color:#ffffff;border:1px solid #ddd;border-radius:5px;margin-top:20px;width:480px;margin:0 auto;padding:12% 6%">
      <tbody>
        <tr style="width:100%">
          <td>
            <p style="font-size:18px;line-height:24px;margin:16px 0;font-weight:bold;text-align:center">Tower Card</p>
            <h1 style="text-align:center">Your verification code</h1>
            <p style="font-size:14px;line-height:24px;margin:16px 0;text-align:center">Enter it in the Tower Card application. This code will expire in 15 minutes.</p>
            <table align="center" width="100%" border="0" cellPadding="0" cellSpacing="0" role="presentation" style="background:rgba(0,0,0,.05);border-radius:4px;margin:16px auto 14px;vertical-align:middle;width:280px;max-width:100%">
              <tbody>
                <tr>
                  <td>
                    <h1 style="color:#000;display:inline-block;padding-bottom:8px;padding-top:8px;margin:0 auto;width:100%;text-align:center;letter-spacing:8px">{verification_number}</h1>
                  </td>
                </tr>
              </tbody>
            </table>
            <table align="center" width="100%" border="0" cellPadding="0" cellSpacing="0" role="presentation" style="margin:27px auto;width:auto">
            </table>
            <p style="font-size:14px;line-height:24px;margin:0;color:#444;letter-spacing:0;padding:0 40px;text-align:center">If you didn't request this code, you can safely ignore this email.</p>
          </td>
        </tr>
      </tbody>
    </table><!--/$-->
  </body>

</html>"""
    params: resend.Emails.SendParams = {
        "from": "onboarding@resend.dev", # may need to change based on sending limits. for testing purposes only.
        "to": ["neha.washikar@gmail.com"],
        "subject": "Your Tower Card Verification Code",
        "html": html_content,
    }
    email_response: resend.Email = resend.Emails.send(params)
    return email_response
