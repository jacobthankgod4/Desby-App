You are working on the Desby application. I want you to perform a deep, production-level UI/UX, responsive-design, functionality, and data-persistence audit across the affected pages and flows described below.

Do not make superficial visual changes. Inspect the existing implementation, components, responsive breakpoints, CSS/Tailwind classes, database queries, Supabase persistence logic, image-loading logic, routing, state management, and reusable layout components. Identify the actual causes of the problems, then implement the fixes at the correct architectural level so the same issues do not reappear on related pages.

Do not break existing working functionality while making these changes.

Before modifying anything, inspect the existing codebase and understand:

* the application shell/layout structure
* shared header and navigation components
* side menu components
* authentication and onboarding flows
* tailor and client profile architecture
* product/fabric data structures
* Supabase tables and relationships
* image storage/buckets/URLs and how product images are retrieved
* checkout and booking flows
* responsive breakpoints for mobile/tablet/desktop
* reusable cards, forms, modals/dialogs, and grid components

Where the same structural issue exists in multiple related pages, fix the shared root component rather than patching each page independently.

==================================================

1. DUPLICATE "MY SHOP" / DUPLICATE PAGE HEADER TEXT
   ==================================================

The page header currently has my shop/shop title in the main header, but there is another duplicate "My Shop" or similar text appearing underneath it inside the page content.

Only the header text is supposed to exist.

Remove the duplicate "My Shop" or equivalent secondary text underneath the header.

This is not limited to one page. Apply the same structural correction to this page and all other related pages that use the same layout pattern.

Important:

* Keep the legitimate header title.
* Remove only the redundant secondary title/text.
* Do not simply hide it visually if it is still being rendered unnecessarily.
* Inspect the page-shell/layout hierarchy to determine why the title is being rendered twice.
* Fix the underlying component structure so related pages do not continue rendering duplicate headings.

Acceptance criterion:
There should be one clear page title in the intended header area and no redundant duplicate title immediately below it.

==================================================
2. PRODUCT IMAGE CARDS ARE BEING CROPPED INCORRECTLY
====================================================

From the referenced screenshot, the product images are visibly cut off and do not properly occupy the intended image-card dimensions.

Perform a deep audit of the product-card image implementation.

Inspect:

* image container dimensions
* aspect-ratio configuration
* object-fit/object-position behavior
* overflow settings
* responsive width and height
* parent container sizing
* image intrinsic dimensions
* whether fixed heights are causing clipping
* whether mobile and desktop use conflicting image styles
* whether the image component itself is applying unintended cropping

The actual product image should fit cleanly and intentionally inside the image card.

The card should maintain a polished, modern aspect ratio without awkward clipping.

Do not arbitrarily distort images.

Choose the correct image behavior based on the existing Desby visual language:

* preserve the product image's visual integrity
* use consistent card dimensions
* ensure the image fills the intended visual area appropriately
* avoid accidental cropping caused by an incorrect height/aspect-ratio combination
* maintain consistency across desktop, tablet, and mobile

Audit every relevant product-image/card implementation rather than only fixing the specific screenshot.

==================================================
3. PRICE INPUT MUST AUTOMATICALLY FORMAT THOUSANDS
==================================================

Price input fields must support human-friendly comma formatting.

For example:

50000 → 50,000
120000 → 120,000
1500000 → 1,500,000

The underlying stored numeric value must remain usable as a number and must not accidentally persist formatting characters as part of the actual numeric value unless the database schema explicitly requires a string.

Implement this properly for all relevant price-input fields.

Requirements:

* Users should be able to type numbers naturally.
* Thousands separators should appear while entering the value.
* Editing an existing price should work correctly.
* Deleting/replacing digits should work correctly.
* Prevent malformed values where practical.
* When submitting, convert the formatted display value into the correct raw numeric value expected by the application/database.
* When loading an existing saved price, render it in the formatted user-facing form.

Example behavior:
Input/display: 50,000
Stored value: 50000

Do not introduce cursor-jumping behavior that makes typing frustrating.

==================================================
4. FABRIC SELECTION CARD IS TRANSPARENT ON MOBILE
=================================================

The fabric-selection card currently becomes transparent or loses its intended background/styling on mobile, while desktop displays the correct implementation.

Perform a responsive CSS audit to determine why the mobile version is not inheriting or applying the same visual treatment.

Compare desktop vs mobile for:

* background
* opacity
* backdrop/filter effects
* borders
* shadows
* card layering
* z-index
* inherited styles
* responsive utility classes
* dark/light theme interactions
* parent transparency
* pseudo-elements

Make the mobile card visually consistent with the intended desktop implementation while still respecting mobile spacing and responsive proportions.

Do not simply force a background color without understanding why the card became transparent.

==================================================
5. "YOUR DESIGNS" — MOBILE DESIGN
=================================

The "Your Designs" section displays tailor-created designs/products.

On mobile, the current implementation should be redesigned so that the actual product image occupies the image card fully.

The visual hierarchy should be image-first.

Requirements:

* The product image should fill the entire image card.
* Do not leave large empty areas around the image.
* Do not incorrectly crop the image.
* Use a polished card aspect ratio appropriate for mobile.
* Overlay key information directly over the image in a highly visible and modern way.

The following should be presented as a visual overlay:

* price
* product name
* product description hint
* product category
* any other essential metadata already part of the card

The overlay should feel intentional, contemporary, and premium rather than looking like ordinary text placed on top of an image.

Consider:

* subtle gradient/contrast treatment behind text
* hierarchy between product name and secondary information
* readable typography
* badges/chips for category where appropriate
* elegant price emphasis
* proper spacing
* touch-friendly interaction
* subtle hover/tap states where applicable

The image must remain the dominant visual element.

==================================================
6. "YOUR DESIGNS" — DESKTOP DESIGN
==================================

The current desktop "Your Designs" section is too large.

Redesign the desktop layout into a modern 5-column image grid.

Requirements:

* exactly 5 image cards per row on desktop where viewport width allows
* responsive behavior should gracefully adapt for smaller desktop/tablet widths
* cards should feel compact but premium
* eliminate excessive card size
* create a modern, dynamic visual rhythm
* maintain consistent card dimensions/aspect ratio
* preserve visual quality of product images

Each card should display the following information in a modern and interactive presentation:

* price
* product name
* product description
* product category

The information should not look like a generic vertical list under each image.

Explore an elegant card system where:

* image is the primary element
* metadata is layered or integrated elegantly
* category can be represented with a modern badge/chip
* price receives strong visual hierarchy
* product title is immediately understandable
* description is concise and visually secondary
* interactions feel intentional and polished

The overall section should feel like a modern fashion/design marketplace rather than a basic admin/product listing.

==================================================
7. SIDE MENU PROFILE CIRCLE SHOULD SHOW USER PHOTO
==================================================

The profile circle in the side menu currently needs to support uploaded profile pictures.

When a user uploads a profile image:

* display the actual uploaded user picture inside the profile circle
* use the correct Supabase/storage/public URL or application image source
* ensure the image is loaded consistently after refresh
* handle missing/invalid image URLs gracefully
* preserve the existing fallback behavior when no image has been uploaded

The image should:

* fit inside the circular container
* use appropriate object-fit behavior
* remain visually centered
* not stretch or distort

Audit the full path:
Upload → persistence → retrieval → state update → side menu rendering → refresh persistence.

==================================================
8. TAILOR "SET YOUR PRICING" PAGE — INPUT HINTS
===============================================

The "Set Your Pricing" page for tailors should not use placeholder text as the primary instructional mechanism.

Tailors should enter their own prices.

Instead of conventional placeholder text inside the input:

* use a subtle light-grey hint/instructional treatment
* the hint should communicate the expected input/value format
* once the tailor starts typing, the grey instructional text should disappear
* the actual field remains clean and focused on the entered value

Do not hard-code an actual price and make it look like the user's current value.

The distinction must be clear:

Hint:
"What should this service cost?"
or an appropriate contextual example

User-entered value:
50,000

The hint is instructional only and should never be saved as data.

Apply this consistently to every relevant pricing field on this page.

==================================================
9. SPLIT-SCREEN LOGIN PAGE IMAGE FIT
====================================

In the attached screenshot, the image on the split-screen login page does not fit its allocated space correctly.

Perform a deep audit of the split-screen layout.

Requirements:

* image must fit perfectly into its assigned panel
* no unexpected clipping
* no stretching/distortion
* no awkward empty gaps
* correct responsive behavior
* preserve the intended focal point of the image
* maintain a polished desktop composition

Audit:

* container dimensions
* image dimensions
* object-fit
* object-position
* min/max heights
* viewport-height assumptions
* flex/grid behavior
* overflow
* responsive breakpoints

On smaller screens, ensure the image behaves intentionally rather than inheriting desktop dimensions.

==================================================
10. REMOVE "NEW ORDER" FROM SIDE MENU AND PAGE
==============================================

Remove the "New Order" side-menu item and the associated page/route/UI.

It is redundant.

This means:

* remove it from navigation
* remove the related page from the user-facing flow
* remove unnecessary links/buttons that lead to it
* ensure no dead navigation remains
* clean up related route usage where appropriate
* do not break other ordering/checkout functionality

Important:
Do not remove the actual ordering capability if other parts of the application use it.

Remove the redundant "New Order" standalone entry/page, not the underlying ordering workflow.

==================================================
11. VIRTUAL TRY-ON — PRODUCT IMAGES NOT DISPLAYING
==================================================

The Virtual Try-On page currently has a serious image-display issue: product images are not appearing.

Do a deep technical audit rather than simply changing the UI.

Investigate the complete image pipeline:

1. Where the products come from.
2. What product fields contain image data.
3. Whether image URLs are being stored correctly.
4. Whether Supabase Storage is involved.
5. Whether the bucket is public or requires signed URLs.
6. Whether URLs are expired.
7. Whether the application is constructing URLs incorrectly.
8. Whether the product query is returning image fields.
9. Whether the frontend is reading the correct property name.
10. Whether images are blocked by permissions/CORS/security configuration.
11. Whether the image component fails silently.
12. Whether there are responsive/rendering issues.
13. Whether broken fallback logic hides the actual error.
14. Whether virtual try-on is expecting a different image schema than the product marketplace.

Use the browser/application runtime and existing project architecture to identify the real root cause.

Do not assume the problem is CSS.

If multiple product-image sources exist, standardize the image-resolution logic where appropriate so the Virtual Try-On page consistently receives a valid displayable image source.

Add robust fallback behavior for missing images, but do not use fallback imagery to hide a broken image-data pipeline.

==================================================
12. FABRIC MARKETPLACE — REMOVE DUPLICATE INNER TITLE
=====================================================

The Fabric Marketplace currently displays "Fabric Marketplace" twice.

One title is already correctly represented in the main shell/header.

The duplicate title inside the content shell must be removed.

This duplicate text is also pushing the marketplace content downward, creating unnecessary vertical spacing and a poorer layout.

Requirements:

* retain the correct shell/header title
* remove the redundant inner "Fabric Marketplace" heading
* recover the vertical space
* ensure marketplace content starts at the correct visual position
* apply the same principle to related pages if they use the same duplicated-heading architecture

Again, fix the underlying layout structure rather than merely hiding the text.

==================================================
13. CLIENT DASHBOARD — PRODUCT IMAGES NOT SHOWING
=================================================

The Client Dashboard currently has product-image rendering issues.

Perform a deep technical audit similar to the Virtual Try-On image audit.

Investigate:

* database query response
* image field names
* relationships/joins
* Supabase Storage
* public vs signed URLs
* URL generation
* frontend mapping
* null/undefined values
* image transformations
* card dimensions
* object-fit
* loading behavior
* authentication-related access restrictions
* caching
* responsive rendering

Determine whether the Client Dashboard and Virtual Try-On are suffering from the same underlying image-data problem.

Where appropriate, create a shared image-resolution utility/component instead of maintaining separate fragile implementations.

Acceptance criterion:
Valid product images stored in the database/storage should render correctly on the Client Dashboard without requiring a manual reload or special workaround.

==================================================
14. CLIENT POST-SIGN-UP ONBOARDING — MULTISELECT PREFERENCES
============================================================

During client post-sign-up onboarding, there is a step where users select:

* preferred occasion
* preferred fabric

These selections are meant to support multiple selection.

Users should be able to select multiple options, not just one.

Requirements:

* multiple options may be selected simultaneously
* selected items have a strong, obvious active state
* users can deselect an option
* state persists correctly while navigating between onboarding steps
* state is correctly saved to Supabase
* previously saved preferences should be correctly restored when the onboarding screen is reopened
* validation should reflect the intended multi-selection behavior
* do not overwrite previously selected values with only the last clicked item

Audit the database representation as well.

Use an appropriate data model for multiple values and ensure frontend state and Supabase storage are consistent.

==================================================
15. STYLE PREFERENCES FROM TAILOR BOOKING PAGE ARE NOT SAVING
=============================================================

The style-preferences page accessed from the tailor booking flow currently appears to accept selections visually, but those selections are not being persisted to Supabase.

Perform a deep audit of the complete save operation.

Inspect:

* selection state
* submit handler
* Supabase mutation
* table name
* column names
* user ID mapping
* tailor/client relationship
* insert vs update behavior
* row-level security policies
* authentication state
* asynchronous errors
* error handling
* optimistic UI state
* data retrieval after save

Do not assume that because the UI changes state, the database save succeeded.

The final implementation must:

1. accept the user's selections
2. write them to Supabase
3. handle insert/update correctly
4. show meaningful error handling when persistence fails
5. retrieve the data correctly later
6. restore the saved selections into the UI

Verify the result after implementation.

==================================================
16. TAILOR PROFILE — "WHAT WE DO" CARDS
=======================================

The "What We Do" section on the tailor profile currently uses only one type of image across the cards.

This should be changed.

Each card should use an image representing the relevant fabric/type/service category.

Requirements:

* different card categories should have visually appropriate images
* do not reuse one generic image for every card unless the actual category intentionally has no unique image
* images should feel fashion-oriented and relevant to the category

The current cards and text are also too tiny.

Redesign the section to make it:

* bold
* engaging
* visually prominent
* easy to scan
* modern
* premium
* consistent with Desby branding

Increase:

* image visibility
* card prominence
* typography scale
* category readability
* spacing
* visual hierarchy

The section should immediately communicate what the tailor offers.

==================================================
17. REMOVE STYLE PREFERENCES FROM TAILOR PROFILE
================================================

The Style Preferences section currently appearing on the tailor profile should not be there.

Remove it from the tailor-profile page.

There are two places where style preferences should conceptually exist:

A. USER SIDE MENU / GENERAL FEED PREFERENCES

Users should have a Style Preferences section accessible from the side menu/settings area.

This represents the styles the user generally loves.

These preferences should influence the user's feed.

For example:

* user chooses preferred styles
* the system stores those preferences
* relevant products/designs shown in the user's feed should be filtered or prioritized according to those preferences

This is a user-level preference system, not a tailor-profile attribute.

B. CHECKOUT PAGE

Style preferences should continue to exist on the checkout page, as they currently do.

These are relevant to the specific tailoring/order request.

Do not remove the checkout version.

The architecture should clearly distinguish:

User-level style preferences
= what the user generally likes and wants to see in their feed.

Checkout/order-level style preferences
= what the user wants for this particular tailoring request/order.

Do not mix these two data concepts.

==================================================
18. REDESIGN CHECKOUT STEP ONE BASED ON THE ACTUAL USER SCENARIO
================================================================

The current Step One on the checkout page is not asking the right questions for the scenario in which it is entered.

Consider the actual flow:

A client clicks on a tailor's profile.

The client has NOT yet clicked on a specific tailor product/design to have that exact product custom-made.

Therefore, the application does not yet know exactly what the client wants sewn.

The current Step One is not correctly solving this scenario.

Redesign Step One around the fundamental discovery questions that should be asked before the tailoring request can proceed.

Think carefully about the minimum core information the tailor needs from the client when there is no predefined product selected.

The first step should establish the client's actual sewing request.

The flow should help answer questions such as:

* What do you want sewn?
* What type of outfit/garment is this?
* Is this for a particular occasion?
* What garment/style are they trying to create?
* Are they requesting something from scratch or adapting a reference?
* Are there important preferences that need to be known before moving forward?

Do not blindly copy these examples if the existing product/business model suggests a more appropriate information structure.

The key requirement is:

STEP ONE MUST FIRST ESTABLISH WHAT THE CLIENT ACTUALLY WANTS THE TAILOR TO MAKE WHEN NO SPECIFIC PRODUCT HAS BEEN PRESELECTED.

The flow should feel simple rather than like a long form.

==================================================
19. CHECKOUT DIALOG MUST BECOME A FULL-PAGE MODERN SPLIT-SCREEN EXPERIENCE
==========================================================================

The checkout/request dialog should not feel like a small conventional modal.

For this tailor-profile entry scenario, transform the experience into a full-page experience inside the application shell.

Use a modern split-screen "pilot" style layout.

The visual structure should feel:

* spacious
* premium
* modern
* guided
* fluid
* immersive

A possible conceptual structure:

LEFT SIDE:
Visual/contextual panel showing:

* tailor context
* relevant design/fashion imagery
* short explanation of the current stage
* progress indicator or visual journey

RIGHT SIDE:
Interactive form area containing:

* current step
* inputs
* selection controls
* continue/back controls
* contextual guidance

The split-screen implementation must still be responsive.

On mobile:

* transition intelligently into a vertically stacked experience
* maintain the same logical flow
* do not simply compress the desktop split-screen into an unusable narrow layout

==================================================
20. CHECKOUT FLOW MUST BE FLUID FROM STEP ONE TO FINAL SUBMISSION
=================================================================

The entire checkout/request journey should be redesigned as one coherent experience.

Do not optimize each step independently while ignoring the overall flow.

The sequence should feel:

* smooth
* predictable
* fluid
* easy to understand
* visually connected
* free from unnecessary repetition

Users should always understand:

* where they are
* what they are doing
* why they are being asked for the information
* what happens next
* how far they are from completion

Use:

* clear progress indicators
* strong hierarchy
* concise instructions
* logical grouping
* sensible defaults where appropriate
* clear Back/Continue actions
* preserved state between steps
* animated transitions where appropriate
* loading states
* validation feedback
* successful save/submission feedback

Avoid:

* confusing field ordering
* unnecessary duplicate questions
* unexplained terminology
* excessive form density
* abrupt transitions
* losing entered information when navigating backward

==================================================
21. FIRST-TIME CHECKOUT TOUR GUIDE
==================================

Users landing on this checkout/request page for the first time should receive a beautiful, modern guided tour.

The purpose is to explain:

* what this checkout flow is
* what each step means
* what information the user is expected to provide
* why the information matters
* what happens after completing each step

Use a modern, free, open-source tour-guide implementation/library that is actively usable for a web application.

Before selecting one, inspect the project stack and select an implementation compatible with the existing technology.

Do not invent a custom tour system unnecessarily if a mature open-source implementation can be cleanly integrated.

The tour should:

* appear only for first-time users or until they explicitly complete/dismiss it
* not become annoying on every visit
* have clear Next / Back / Skip controls where appropriate
* visually highlight the exact UI section being explained
* work on desktop and mobile
* not break the checkout interaction underneath
* respect accessibility
* support keyboard navigation
* work with screen readers as far as the chosen library supports it
* preserve the Desby brand experience

Use Desby contextual colors and styling.

The tour should feel like part of Desby rather than a generic third-party component.

Potential implementation behavior:

* welcome/overview
* explain Step One
* explain the main selections/inputs
* explain supporting style preferences
* explain progress/navigation
* explain final submission/review

The exact tour sequence should be based on the final checkout implementation.

Store the user's tour-completion state so that completed users are not repeatedly shown the onboarding tour.

Do not simply use local state if the application's existing architecture requires cross-device persistence; determine the appropriate persistence strategy.

==================================================
22. OVERALL RESPONSIVE DESIGN AUDIT
===================================

Do a broader responsive audit across every affected page.

Do not treat mobile as an afterthought.

Check:

* mobile widths
* tablet widths
* desktop widths
* large desktop widths
* card dimensions
* typography
* image ratios
* spacing
* overflow
* scrolling
* fixed/sticky elements
* navigation
* side menu behavior
* modal/dialog behavior
* input usability
* touch targets
* long text
* loading states
* empty states

The design must remain visually intentional at all breakpoints.

Where desktop and mobile currently behave differently, determine whether the difference is intentional or a bug.

==================================================
23. IMAGE SYSTEM AUDIT
======================

Because several pages have image-related problems, perform a cross-application image audit.

Affected areas include at minimum:

* Product cards
* Your Designs
* Virtual Try-On
* Client Dashboard
* Tailor profile What We Do cards
* Login split-screen image
* Fabric-related cards

Determine whether there are common underlying problems in:

* Supabase Storage
* image URL construction
* database fields
* bucket permissions
* signed/public URLs
* frontend image components
* image loading states
* broken-image fallback
* responsive image rendering

Where possible, create a reliable shared image-resolution/rendering pattern so the application is not solving the same image problem differently on every page.

Do not mask broken image data with placeholders without investigating the source.

==================================================
24. SUPABASE / DATA INTEGRITY AUDIT
===================================

Perform a deep audit of all affected data flows.

Especially verify:

* user profile images
* style preferences
* occasion preferences
* fabric preferences
* tailor pricing
* product images
* tailor products/designs
* checkout/request information

For every persistence-dependent feature, verify:

UI input
→ application state
→ transformation
→ Supabase mutation
→ successful database write
→ data retrieval
→ UI rehydration after refresh

Check for:

* incorrect column names
* incorrect IDs
* stale state
* race conditions
* failed promises
* missing awaits
* silent errors
* RLS policy failures
* incorrect relationships
* insert/update conflicts
* serialization issues
* array vs string mismatches

Errors should be surfaced clearly during development and handled appropriately in production.

==================================================
25. DESIGN DIRECTION
====================

The finished implementation should feel like a modern fashion-tech product.

Do not make the UI feel like:

* a generic dashboard
* a basic CRUD application
* a conventional admin panel
* a collection of unrelated components

The experience should feel:

* modern
* premium
* fashion-forward
* interactive
* dynamic
* clean
* visually confident
* easy to understand

Use the existing Desby design language and contextual colors instead of introducing an unrelated visual identity.

Do not overdecorate the interface.

The goal is strong visual hierarchy and thoughtful interaction, not visual noise.

==================================================
26. IMPLEMENTATION QUALITY
==========================

Do not solve these issues by adding random CSS overrides at the bottom of files.

Prefer:

* fixing shared components
* fixing data flow
* fixing reusable image components
* fixing layout architecture
* cleaning duplicated components
* consolidating repeated logic
* improving responsive abstractions
* reusing existing design primitives

Avoid:

* duplicate code
* one-off hacks
* unnecessary dependencies
* hidden elements that remain structurally present when they should be removed
* hardcoded user data
* fake placeholder data
* silent database failures

Keep existing functionality intact unless this prompt explicitly asks for its removal or redesign.

==================================================
27. TESTING AND VERIFICATION
============================

After implementation, test each affected flow.

At minimum verify:

HEADER / SHELL

* no duplicate My Shop/page titles
* no duplicate Fabric Marketplace title

PRODUCTS

* images render correctly
* images are not unintentionally cropped
* card proportions are correct
* prices format correctly

YOUR DESIGNS

* mobile image fills card
* metadata overlays correctly
* desktop displays a 5-column grid
* cards remain responsive

PROFILE

* uploaded profile picture appears in side menu
* fallback works when no picture exists

TAILOR PRICING

* no fake placeholder prices
* grey hints disappear when typing
* comma formatting works
* saved values remain numerically correct

LOGIN

* split-screen image fits perfectly

NAVIGATION

* New Order removed from side menu
* redundant New Order page removed
* existing order/checkout functionality remains intact

VIRTUAL TRY-ON

* actual product images load
* image source/path issue is resolved

CLIENT DASHBOARD

* product images load correctly

ONBOARDING

* preferred occasion supports multiple selection
* preferred fabric supports multiple selection
* selections persist correctly

STYLE PREFERENCES

* tailor-profile style preference removed
* user-level style preferences exist in side menu/settings
* user-level preferences can influence the feed
* checkout-specific style preferences remain

TAILOR PROFILE

* What We Do cards have varied, relevant images
* cards and typography are substantially more visible

CHECKOUT

* Step One correctly starts with understanding what the client wants sewn
* full-page split-screen flow works
* all steps are logically ordered
* navigation between steps retains state
* validation is clear
* final submission works
* first-time tour works
* tour does not repeatedly annoy returning users
* tour works responsively

==================================================
28. FINAL REQUIREMENT
=====================

Do not simply report what is wrong.

You are expected to:

1. inspect the existing implementation
2. identify the root causes
3. implement the fixes
4. verify the affected flows
5. clean up redundant code/routes/components where appropriate
6. ensure the new design remains consistent with the existing Desby architecture

For every issue involving data or images, verify both the frontend behavior and the underlying source/data flow.

For every issue involving responsive design, verify both desktop and mobile behavior.

For every issue involving persistence, verify actual Supabase writes and retrieval rather than assuming the UI state means the operation succeeded.

For every issue involving duplicated UI, fix the shared rendering architecture where possible.

The end result should feel like a cohesive, production-ready evolution of Desby rather than a collection of isolated fixes.
