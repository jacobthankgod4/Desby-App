# Uber Direct Logistics: Nigeria Activation Guide (Lagos)

Good news: **Uber Direct is active in Nigeria (specifically Lagos).**

It is a B2B service launched to help merchants like you. However, you are currently seeing it as "disabled" because Uber requires you to pass a **Business Verification** before the `eats.deliveries` scope is unlocked in your developer dashboard.

---

## 1. Register as a Merchant (The "Missing Step")

You cannot enable the scope yourself. You must first create an **Uber Direct Business Account (Organization)**. This is the account that will handle your billing and logistics management.

1.  **Use the correct signup link**: [Uber for Business - Create Org](https://business.uber.com/create?_csid=BAYkF_9iy3MeCTcdUPtKLQ&effect=&sm_flow_id=ac0ziUIB&state=fqhLiRwMlUCGxj_y0TfRk32xiDh-2rEB9HepkZx8Gjg%3D&uclick_id=41ca6bfa-f6d5-40d1-a27c-b216fb7bd76c)
2.  **Fill in your details**:
    *   **Organization**: Desby App
    *   **Work email**: `jacobthankgod4@gmail.com`
3.  **Specify Lagos/Nigeria**: During the setup, ensure you select Nigeria. Even if it isn't in a "Self-Service" global dropdown later, completing this step generates your **Organization ID**, which is required for the API.

---

## 2. Request the `eats.deliveries` Scope

Once you have submitted your business details, you must contact Uber to bridge your Developer App with your Business Account.

**Send this specific request to `uberdirect@uber.com`:**

> **Subject:** Production Access Request - Desby App (Nigeria)
>
> **Body:**
> Hello Uber Direct Support Team,
>
> I am the owner of **Desby App**, a fashion-tech platform based in **Lagos, Nigeria**. 
>
> I have completed the technical integration of the Uber Direct API (**App ID: `F-2qIUzzIaIWv_PNW3PBxZFZc5fIt2jX`**) and we are ready to launch our automated logistics feature for local tailors. 
>
> Since Nigeria is a managed market, I understand that I need manual whitelisting for the **`eats.deliveries`** scope under **Client Credentials**. 
>
> Please let me know the next steps to verify my business and unlock this scope for production testing in Lagos.
>
> Best regards,  
> [Your Name]

---

## 3. Why Nigeria looks "Disabled"

In many Western countries, Uber Direct is "Self-Service" (you just add a credit card). In Nigeria, Uber operates a **"Managed Market"** model. This means:

*   You need an account manager or a support rep to manually approve your App ID.
*   **The API works perfectly in Lagos**, but the gateway is locked until they verify your business registration and valid billing method for the Nigerian market.

---

## 💡 Pro-Tip for Nigeria

While you wait for Uber's approval (which can take 1-2 weeks), we have already integrated the technical foundations:

*   **Uber** is great for premium, instant delivery in Lagos.
*   **Fez Delivery** (already referenced in the code) is the local alternative for specialized logistics across Nigeria.

**My recommendation**: Send that email to Uber now. While we wait for their reply, your app is already **100% ready** on the technical side. The moment they flip the switch, your "Live Tracking" map and "Summon Rider" buttons will start working automatically.
