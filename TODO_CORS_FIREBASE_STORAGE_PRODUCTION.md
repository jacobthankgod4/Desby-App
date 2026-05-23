# Desby OS - Live Mode Launch Checklist

*Status: Ready for Production Launch*

---

## 1. Firebase Security Rules

### Authentication
- [ ] **Enable Production Auth Rules**: Only allow verified users
- [ ] **Enable Email Verification**: Require email verification before login
- [ ] **Add Rate Limiting**: Prevent brute force attacks
- [ ] **Configure Trusted Networks**: If needed

```python
# Firebase Auth Rules (in Console → Authentication → Settings)
✅ Enable "Email link (passwordless sign-in)" - optional
✅ Enable "Identity Platform" - if using advanced features
```

### Firestore Database Rules
- [ ] **Lock Production Rules**:
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    // Add other collection rules
  }
}
```

### Storage Rules
- [ ] **Lock Production Rules**:
```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /profiles/{userId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    match /fabrics/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null; // Or custom rules
    }
  }
}
```

---

## 2. Firebase Project Settings

### General
- [ ] **Set Support Email**: Add support contact
- [ ] **Configure Public Facing Name**: "Desby OS"
- [ ] **Add Privacy Policy URL**: If hosted
- [ ] **Add Terms of Service URL**: If hosted

### App Distribution (Optional)
- [ ] **Remove Test Users**: Clean up test accounts
- [ ] **Configure App Distribution**: If using for beta testing

---

## 3. API Keys & Credentials

### Security
- [ ] **Restrict API Keys**: Limit to your app domains
  - Go to: Google Cloud Console → APIs & Services → Credentials
  - Add HTTP referrer restrictions for web API key
- [ ] **Rotate Sensitive Keys**: If any were exposed
- [ ] **Enable Firebase App Check**: Verify requests (optional, recommended)

### Environment Variables
- [ ] **Verify Production Config**: No localhost references
- [ ] **Check Debug Mode Disabled**: Set `kDebugMode = false` for release

---

## 4. Cloud Functions (If Used)

### Security
- [ ] **Set .env for Production**: Database URLs, API keys
- [ ] **Configure Memory & Timeout**: Optimize for production
- [ ] **Add Rate Limiting**: Prevent abuse
- [ ] **Set VPC Connector**: If needed for sensitive data

---

## 5. Payment & Subscriptions

### Stripe Integration (If Using)
- [ ] **Use Live Stripe Keys**: Replace test keys with production
- [ ] **Configure Webhooks**: Point to production URL
- [ ] **Test in Stripe Test Mode**: Verify payment flow works
- [ ] **Enable Stripe Billing**: Set up subscription plans

### Pricing Rules
- [ ] **Review Firebase Blaze Plan Budget**: Set alerts
- [ ] **Enable Usage Alerts**: Get notified of high usage

---

## 6. Monitoring & Analytics

### Firebase Crashlytics
- [ ] **Enable Crashlytics**: Auto-capture crashes
- [ ] **Verify Symbolication**: For native crashes

### Firebase Analytics
- [ ] **Configure Events**: Track key user actions
- [ ] **Set Up Audiences**: For user segmentation
- [ ] **Create Dashboards**: Monitor key metrics

### Error Tracking
- [ ] **Enable Error Boundaries**: In Flutter code
- [ ] **Set Up Sentry (Optional)**: Additional error tracking

---

## 7. Domain & SSL

### Domain Configuration
- [ ] **Configure Custom Domain** (Optional): If using custom domain
- [ ] **Set Up DNS Records**: Point to Firebase Hosting
- [ ] **Enable SSL**: Automatic with Firebase Hosting

### OAuth Redirects
- [ ] **Add Production Domains**: To Firebase Console → Authentication → Settings
- [ ] **Add Authorized JavaScript Origins**:
  - `https://desby-os.web.app`
  - `https://desby-os.firebaseapp.com`
  - Your custom domain (if any)

---

## 8. Test Production Flow

### Pre-Launch Testing
- [ ] **Create Test Account**: Verify full flow
- [ ] **Test Registration**: Email verification works
- [ ] **Test Login**: Authentication works
- [ ] **Test Onboarding**: All user types complete
- [ ] **Test Profile Upload**: Image upload to Firebase Storage
- [ ] **Test Orders**: Full order creation process
- [ ] **Test Payments**: If integrated
- [ ] **Test Logout**: Session cleared properly

### Performance Testing
- [ ] **Run Flutter Build**: Verify no issues
```bash
flutter build web --release
```
- [ ] **Test Lighthouse Score**: Target 90+ for performance
- [ ] **Test on Slow Network**: Ensure graceful fallbacks

---

## 9. Legal & Compliance

### Privacy & Terms
- [ ] **Publish Privacy Policy**: Required for app stores
- [ ] **Publish Terms of Service**: Required for app stores
- [ ] **Configure Cookie Consent**: If using analytics (GDPR)

### App Store Requirements
- [ ] **Apple App Store**: Prepare App Store information
- [ ] **Google Play Store**: Prepare Play Store information
- [ ] **Age Rating**: Complete age rating questionnaire

---

## 10. Pre-Launch Final Checks

### Code
- [ ] **Remove All Debug Prints**: Clean up `debugPrint`
- [ ] **Enable Release Mode**: No debug assertions
- [ ] **Check Image Optimization**: Use WebP, lazy loading
- [ ] **Verify Memory Leaks**: Run with --enable-asserts

### Infrastructure
- [ ] **Set Up CI/CD**: GitHub Actions or similar
- [ ] **Configure Deployment**: Auto-deploy from main branch
- [ ] **Set Up Backups**: If using custom backend

### Team Access
- [ ] **Review Team Members**: Only needed people have access
- [ ] **Set Up Admin Access**: Define admin users in Firestore
- [ ] **Configure Support Access**: For customer support

---

## Launch Sequence

### Week Before Launch
- [ ] Run production build locally
- [ ] Test all user flows
- [ ] Enable production Firebase rules
- [ ] Set up monitoring dashboards

### Launch Day
- [ ] Deploy to Firebase Hosting
```bash
firebase deploy --only hosting
```
- [ ] Monitor Crashlytics & Analytics
- [ ] Verify all external services work

### Post-Launch
- [ ] Monitor error rates (Crashlytics)
- [ ] Monitor performance (Analytics)
- [ ] Respond to user feedback
- [ ] Plan iterations based on data

---

## Key URLs for Launch

- **App**: https://desby-os.web.app
- **Console**: https://console.firebase.google.com/project/desby-os
- **Analytics**: https://console.firebase.google.com/project/desby-os/analytics
- **Storage**: https://console.firebase.google.com/project/desby-os/storage

---

*Created: $(date)*
*For: Desby OS Production Launch*
