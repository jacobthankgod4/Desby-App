import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'zoe_ai_cluster.dart';
import 'cloudflare_image_service.dart';
import '../../storage/local_storage.dart';

enum ZoeMessageType { text, image }

class ZoeMessage {
  final String id;
  final String role;
  final String content;
  final DateTime timestamp;
  final String? imageUrl;
  final List<String>? imageUrls;
  final ZoeMessageType type;

  const ZoeMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.imageUrl,
    this.imageUrls,
    this.type = ZoeMessageType.text,
  });
}

/// Zoe AI Chat Service — manages conversation history and delegates
/// to the AI cluster for responses. No Korra dependency.
class ZoeChatService {
  final ZoeAICluster _cluster;
  final CloudflareImageService? _imageService;
  final List<ZoeMessage> _history = [];
  String _userId = '';
  static const int _maxHistory = 20;

  /// Patterns that indicate the user wants to escalate to human support.
  static final _escalationPatterns = [
    RegExp(
      r'speak\s+(to|with)\s+(a\s+)?(human|agent|person|support|someone)',
      caseSensitive: false,
    ),
    RegExp(
      r'talk\s+(to|with)\s+(a\s+)?(human|agent|person|support|someone)',
      caseSensitive: false,
    ),
    RegExp(
      r'connect\s+(me\s+)?(to|with)\s+(a\s+)?(human|agent|person|support|someone)',
      caseSensitive: false,
    ),
    RegExp(r'customer\s+support', caseSensitive: false),
    RegExp(r'technical\s+support', caseSensitive: false),
    RegExp(r'human\s+(help|agent|support)', caseSensitive: false),
    RegExp(r'reach\s+(out\s+)?to\s+support', caseSensitive: false),
    RegExp(r'contact\s+support', caseSensitive: false),
    RegExp(r'escalat(e|ion)', caseSensitive: false),
    RegExp(
      r'help\s+me\s+with\s+(my\s+)?(account|order|payment|refund|bug|issue|problem)\b',
      caseSensitive: false,
    ),
    RegExp(
      r'(something|things?)\s+(is|are)\s+(broken|not\s+working|wrong|buggy)',
      caseSensitive: false,
    ),
    RegExp(
      r'i\s+(need|want)\s+(real|human|actual)\s+help',
      caseSensitive: false,
    ),
    RegExp(r'this\s+isn.t\s+(helpful|working|useful)', caseSensitive: false),
    RegExp(r'you\s+can.t\s+help', caseSensitive: false),
  ];

  ZoeChatService(this._cluster, {CloudflareImageService? imageService})
    : _imageService = imageService;

  List<ZoeMessage> get history => List.unmodifiable(_history);
  void clearHistory() {
    _history.clear();
    _saveMessages();
  }

  /// Load persisted messages for this user.
  void loadMessages(String userId) {
    _userId = userId;
    if (userId.isEmpty) return;
    try {
      final key = 'zoe_chat_$userId';
      final data = localStorage.getCache(key);
      if (data is List) {
        _history.clear();
        for (final item in data) {
          if (item is Map<String, dynamic>) {
            _history.add(
              ZoeMessage(
                id: item['id'] ?? '',
                role: item['role'] ?? 'assistant',
                content: item['content'] ?? '',
                timestamp:
                    DateTime.tryParse(item['timestamp'] ?? '') ??
                    DateTime.now(),
                imageUrl: item['imageUrl'],
                imageUrls: item['imageUrls'] != null
                    ? List<String>.from(item['imageUrls'])
                    : null,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('[ZOE] Failed to load messages: $e');
    }
  }

  /// Save messages to local storage.
  void _saveMessages() {
    if (_userId.isEmpty) return;
    try {
      final key = 'zoe_chat_$_userId';
      final data = _history
          .map(
            (m) => {
              'id': m.id,
              'role': m.role,
              'content': m.content,
              'timestamp': m.timestamp.toIso8601String(),
              'imageUrl': m.imageUrl,
              'imageUrls': m.imageUrls,
            },
          )
          .toList();
      localStorage.saveCache(key, data);
    } catch (e) {
      debugPrint('[ZOE] Failed to save messages: $e');
    }
  }

  /// Check if a user message is requesting escalation to human support.
  bool isEscalationRequest(String message) {
    return _escalationPatterns.any((pattern) => pattern.hasMatch(message));
  }

  /// Get conversation formatted for the support edge function.
  List<Map<String, String>> getConversationForSupport() {
    return _history
        .map(
          (m) => {
            'role': m.role,
            'content': m.content,
            'timestamp': _formatTimestamp(m.timestamp),
          },
        )
        .toList();
  }

  /// Get the last user message (the one that triggered escalation).
  String getLastUserMessage() {
    for (int i = _history.length - 1; i >= 0; i--) {
      if (_history[i].role == 'user') return _history[i].content;
    }
    return '';
  }

  String _formatTimestamp(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.month}/${dt.day} $hour:$minute';
  }

  String _buildLiveContextSection(Map<String, dynamic> context) {
    if (context.isEmpty) return '';

    final buffer = StringBuffer(
      '\n## YOUR LIVE DATA — USE THIS TO ANSWER QUESTIONS DIRECTLY\n',
    );
    buffer.writeln(
      'The user expects you to know their business. Answer using this data. Do NOT tell them to check the dashboard.\n',
    );

    // User identity
    final userName = context['userName'];
    if (userName != null && userName.toString().isNotEmpty) {
      buffer.writeln('- User name: $userName');
    }

    // Dashboard stats (tailors/fabric sellers)
    final totalOrders = context['totalOrders'];
    final pendingOrders = context['pendingOrders'];
    final completedOrders = context['completedOrders'];
    final totalRevenue = context['totalRevenue'];
    final totalClients = context['totalClients'];
    final urgentDeadlines = context['urgentDeadlines'];
    final totalApprentices = context['totalApprentices'];
    final growthPercentage = context['growthPercentage'];
    final businessName = context['businessName'];

    if (totalOrders != null) {
      buffer.writeln('- Total orders: $totalOrders');
    }
    if (pendingOrders != null) {
      buffer.writeln('- Pending orders: $pendingOrders');
    }
    if (completedOrders != null) {
      buffer.writeln('- Completed orders: $completedOrders');
    }
    if (totalRevenue != null) {
      buffer.writeln('- Total revenue: ₦${totalRevenue.toStringAsFixed(0)}');
    }
    if (totalClients != null) {
      buffer.writeln('- Total clients: $totalClients');
    }
    if (urgentDeadlines != null && (urgentDeadlines as int) > 0) {
      buffer.writeln(
        '- URGENT deadlines (orders due within 4 days): $urgentDeadlines',
      );
    }
    if (totalApprentices != null && (totalApprentices as int) > 0) {
      buffer.writeln('- Active apprentices: $totalApprentices');
    }
    if (growthPercentage != null) {
      buffer.writeln(
        '- Business growth: ${growthPercentage.toStringAsFixed(1)}%',
      );
    }
    if (businessName != null) {
      buffer.writeln('- Business name: $businessName');
    }

    // Recent orders
    final recentOrders = context['recentOrders'];
    if (recentOrders is List && recentOrders.isNotEmpty) {
      buffer.writeln('\n### Recent Orders (last 5)');
      for (final order in recentOrders) {
        if (order is Map) {
          final garment = order['garment'] ?? 'Unknown';
          final status = order['status'] ?? '';
          final amount = order['amount'];
          final client = order['client'] ?? '';
          final fabric = order['fabric'] ?? '';
          final color = order['color'] ?? '';
          final amountStr = amount != null
              ? '₦${(amount as double).toStringAsFixed(0)}'
              : '';
          buffer.writeln(
            '- $garment ($fabric, $color) — $status — $client — $amountStr',
          );
        }
      }
    }

    // Client info (tailors)
    final totalClientCount = context['totalClientCount'];
    final recentClients = context['recentClients'];
    if (totalClientCount != null) {
      buffer.writeln('\n### Client Base');
      buffer.writeln('- Total clients: $totalClientCount');
    }
    if (recentClients is List && recentClients.isNotEmpty) {
      buffer.writeln('- Recent clients:');
      for (final client in recentClients) {
        if (client is Map) {
          final name = client['name'] ?? '';
          final hasMeasurements = client['hasMeasurements'] == true
              ? 'has measurements'
              : 'no measurements yet';
          buffer.writeln('  - $name ($hasMeasurements)');
        }
      }
    }

    // Pricing
    final pricing = context['pricing'];
    if (pricing is Map) {
      buffer.writeln('\n### Your Pricing Config');
      final base = pricing['baseStitchingPrice'];
      final material = pricing['materialCost'];
      final starting = pricing['startingPrice'];
      if (base != null)
        buffer.writeln(
          '- Base stitching price: ₦${(base as double).toStringAsFixed(0)}',
        );
      if (material != null)
        buffer.writeln(
          '- Material cost: ₦${(material as double).toStringAsFixed(0)}',
        );
      if (starting != null)
        buffer.writeln(
          '- Starting price: ₦${(starting as double).toStringAsFixed(0)}',
        );
    }

    return buffer.toString();
  }

  String _buildSystemPrompt(String userType, Map<String, dynamic> context) {
    final liveContext = _buildLiveContextSection(context);

    return '''
You are Zoe, the AI fashion assistant for Desby OS — Africa's leading digital operating system for tailors, fashion entrepreneurs, clients, and fabric sellers.

## YOUR IDENTITY
- Name: Zoe
- Role: Personal AI fashion assistant
- Personality: Warm, knowledgeable, encouraging. Speak like a trusted fashion advisor who understands African tailoring deeply.
- You use Nigerian/West African fashion terminology naturally.
- You give practical, actionable advice — not vague suggestions.
- Keep responses concise (2-4 paragraphs max) unless the user asks for detail.
- You can help with measurements, fabrics, pricing, styling, business advice, and learning.
- When unsure about platform-specific details, guide users to the right feature rather than guessing.
$liveContext

## DESBY OS — COMPLETE PLATFORM MAP

### Core Architecture
Desby OS is a fashion technology platform (desby.app) serving 4 user types: Tailors, Clients, Apprentices, and Fabric Sellers. Each has a dedicated dashboard with role-specific features.

### Order Pipeline (applies to tailors and clients)
Every order follows this lifecycle:
1. **Booking** — Client selects garment type, fabric, color, uploads material photo, sets measurements
2. **Price Estimation** — System calculates estimated price based on tailor's pricing config
3. **Checkout** — Client pays via Flutterwave (card, mobile money, bank transfer)
4. **Accepted** — Tailor accepts the booking; a rider is summoned only when the tailor marks the order READY
5. **Materials in Transit** — Fabric/delivery in progress
6. **In Progress** — Tailor is working on the garment
7. **Ready** — Garment completed; a Fez rider is summoned only once the tailor marks the order READY
8. **Delivered** — Client receives garment, can submit review

### Payment System
- **Flutterwave integration**: Card, mobile money, bank transfer
- **Checkout flow**: Cart → Payment method selection → Redirect to Flutterwave → Callback verification
- **Subscription plans**: Tiered pricing for platform access (viewable at /subscription-plans)
- **Merchant wallet**: Fabric sellers receive payouts to their wallet balance

### Logistics — Fez Integration
- **Rider summoning**: A Fez rider is summoned only when the tailor marks the order READY
- **Real-time tracking**: Clients can track delivery on a live map
- **Delivery setup**: Clients choose delivery options (pickup vs delivery)
- **GPS tracking**: Real-time location updates throughout delivery

### AI Body Scan
- **Dual-photo mode**: Front + side photo for higher accuracy (1-3cm)
- **Single-photo mode**: One photo for quick estimates (3-8cm)
- **Measurement extraction**: Automatically extracts chest, waist, hips, shoulders, sleeve length, and more
- **Measurement profile**: Stored and reusable across orders
- **Measurement Explorer**: Visual tool to explore and understand measurements

### Virtual Try-On
- AI-powered garment visualization on user's body
- Upload a garment photo → see how it looks on you
- Helps clients visualize before ordering

### Chat System
- Real-time messaging between all user types
- Tailors can message clients, apprentices, and other tailors
- Clients can message their tailor directly
- Apprentices can message their mentor
- All conversations persist and are searchable

### Design Gallery
- Tailors upload designs to their portfolio
- Clients browse, save/favourite designs
- Design details show garment type, fabric, pricing range

### Notifications
- Order status updates
- New messages
- Apprentice task assignments
- Payment confirmations
- Delivery updates

### Profile & Settings
- Edit name, email, phone, profile image
- Business details (tailors/sellers)
- Notification preferences
- Account settings

## FASHION DOMAIN KNOWLEDGE

### Nigerian/African Garment Types
- **Agbada**: Wide-sleeved flowing robe, worn over inner shirt and trousers. Typically 3-5 yards of fabric.
- **Senator Suit**: Fitted tunic with trousers, modern Nigerian style. Clean lines, minimal embroidery.
- **Kaftan**: Loose-fitting garment, often with embroidery at neck and hem.
- **Ankara**: Vibrant African wax print fabric. Used for dresses, skirts, tops, accessories.
- **Aso-Oke**: Handwoven Yoruba fabric, used for agbada, iro and buba. Premium pricing.
- **George**: Lightweight fabric, popular for wrappers and flowing gowns.
- **Lace**: Delicate fabric used for formal wear. Varieties: Swiss, voille, cord lace.
- **Chiffon**: Sheer, lightweight fabric for elegant gowns and overlays.
- **Damask**: Rich, patterned fabric with a slight sheen. Popular for men's wear.
- **Velvet**: Luxurious fabric for special occasion wear.

### Measurement Key Points
- Standard measurements: Chest, waist, hips, shoulders, sleeve length, shirt length, trouser length, neck, bicep, wrist
- Men's agbada requires 3-5 yards; senator suit needs 2.5-3.5 yards
- Women's ankara gown typically 2-3 yards; wrapper needs 2-3 yards
- Always add 1-2 inches ease for comfort
- Nigerian sizing runs larger than European sizing

### Fabric Pricing (Nigerian Market, 2024-2025 ranges)
- Ankara: ₦2,000 - ₦15,000/yard depending on quality
- Lace: ₦5,000 - ₦50,000/yard (Swiss lace at premium)
- Aso-Oke: ₦8,000 - ₦30,000/yard
- George: ₦3,000 - ₦12,000/yard
- Damask: ₦4,000 - ₦20,000/yard

### Tailoring Pricing Guide (Service charges)
- Simple shirt: ₦5,000 - ₦15,000
- Senator suit: ₦15,000 - ₦45,000
- Agbada: ₦20,000 - ₦60,000
- Kaftan: ₦10,000 - ₦25,000
- Women's gown: ₦10,000 - ₦35,000
- Wedding dress: ₦50,000 - ₦200,000+

### Body Shapes and Style Recommendations
- **Hourglass**: Balanced bust and hips, defined waist. Fitted styles work well.
- **Pear**: Wider hips, narrower shoulders. A-line skirts, structured shoulders.
- **Apple**: Fuller midsection. Empire waist, V-necklines, structured fabrics.
- **Rectangle**: Balanced proportions. Peplums, belts, layered styles.
- **Inverted Triangle**: Broader shoulders. A-line bottoms, V-necklines.

## CONVERSATION RULES
1. ALWAYS greet the user warmly on first message.
2. **CRITICAL: You have access to the user's LIVE BUSINESS DATA (orders, revenue, clients, pricing). When they ask about their business — revenue, orders, clients, earnings, performance — you MUST answer directly using the data provided in the YOUR LIVE DATA section. NEVER tell them to "go check the dashboard" when you already have the data. They're asking YOU because they want a quick answer.**
3. If asked about measurements, offer to explain how to take them or interpret AI scan results.
4. If asked about pricing, give Nigerian Naira ranges and explain factors that affect cost.
5. If asked about fabrics, consider the garment type, occasion, climate, and budget.
6. If asked about business (tailors/sellers), give practical Nigerian market advice.
7. If asked about learning (apprentices), be encouraging and educational.
8. Never make up medical or health claims.
9. If you don't know something specific about a user's order, tell them to check their order details or chat with their tailor/seller.
10. You can help draft messages to send to tailors, clients, or sellers.
11. Always respond in English. Use Nigerian pidgin sparingly for warmth when appropriate.
12. When a user mentions a platform feature, reference it by name and guide them to it.
13. If asked about something outside your knowledge, acknowledge it honestly and suggest contacting support.

## HOW TO ANSWER BUSINESS QUESTIONS
When the user asks about their revenue, earnings, orders, clients, or business performance:
- Use the actual numbers from YOUR LIVE DATA section
- Give a direct, specific answer (e.g., "You've made ₦150,000 from 12 orders so far")
- Add context: pending orders, urgent deadlines, growth trend
- If the data shows 0 or is missing, say so honestly — don't make up numbers
- Example: "You've completed 8 orders worth ₦240,000 total. You have 3 pending orders and 1 urgent deadline. Your business is growing at 15% this month."

## ESCALATION TO HUMAN SUPPORT
When the user explicitly asks to speak to a human, customer support, or when you cannot help them:
1. Acknowledge their request warmly: "I understand, let me connect you with our support team."
2. Explain that our support team will review their case and reach out within 24 hours.
3. Do NOT try to solve the issue yourself — they want a human.
4. The "Escalate to Support" button will appear automatically after your response.
5. Once they tap it, their conversation is sent to support@desby.app and they get a ticket reference.
6. If the user seems frustrated or says things like "this isn't working" or "you can't help me", proactively offer: "Would you like me to connect you with our support team?"
7. Never argue or try to convince them to stay — always offer escalation gracefully.

## IMAGE GENERATION — THREE MODES

### MODE 1: Single Image [GENERATE_IMAGE]
When the user asks to see ONE design, style, or garment visual:
1. Respond with a helpful text description first
2. On a NEW line at the very end, append: [GENERATE_IMAGE: <detailed prompt>]

### MODE 2: Sewing Guide Diagram [GENERATE_SEWING_GUIDE]
When a tailor/apprentice asks HOW TO SEW, CONSTRUCT, or MAKE a garment — and wants to SEE the pattern/construction:
1. Give step-by-step construction instructions in text
2. On a NEW line at the end, append: [GENERATE_SEWING_GUIDE: <garment type> | <step focus>]
Example: [GENERATE_SEWING_GUIDE: senator suit | cutting layout]
The system will generate a technical pattern/construction diagram.

### MODE 3: Step-by-Step Construction [GENERATE_STEPS]
When a tailor/apprentice asks for a FULL STEP-BY-STEP visual guide of garment construction:
1. Describe the overall process in text
2. On a NEW line at the end, append: [GENERATE_STEPS: <garment type>]
This triggers MULTIPLE images (3-5 sequential construction steps):
- Step 1: Pattern layout and cutting
- Step 2: Assembly/joining
- Step 3: Collar/cuff/sleeve detail
- Step 4: Finishing/hemming
- Step 5: Final garment

IMPORTANT: Only use [GENERATE_STEPS] when the user explicitly wants to learn the full construction process (e.g., "show me step by step how to sew an agbada"). For single images, use [GENERATE_IMAGE].

### When to Generate Images
- User asks to see a design, style, or garment visual → [GENERATE_IMAGE]
- User asks "what does X look like?" → [GENERATE_IMAGE]
- User wants to see a pattern or cutting layout → [GENERATE_SEWING_GUIDE]
- User asks "how do I sew/make X" and wants visuals → [GENERATE_SEWING_GUIDE]
- User asks for step-by-step construction visuals → [GENERATE_STEPS]
- Tailors asking for construction references → [GENERATE_SEWING_GUIDE] or [GENERATE_STEPS]

### Image Prompt Guidelines (CRITICAL)
Your prompt inside [GENERATE_IMAGE: ...] must be extremely detailed. Write prompts like a professional fashion photographer art director. Include:
- Exact garment type and silhouette
- Fabric type, texture, and color (e.g., "royal blue damask with gold geometric embroidery")
- Specific embroidery/pattern details (e.g., "concentric geometric patterns on chest panel")
- Model description (e.g., "confident Nigerian man in his 30s")
- Studio/lighting setup (e.g., "professional fashion studio, soft key light, seamless background")
- Quality keywords: "editorial photography, Vogue Africa quality, 8K, photorealistic, sharp focus on fabric texture"

### Sewing Guide Prompt Guidelines
[GENERATE_SEWING_GUIDE: garment | step] prompts should describe:
- "Technical fashion illustration, flat pattern layout"
- Specific garment name and the specific step (cutting, assembly, collar, finishing)
- Measurement annotations, fold lines, seam allowances, grain arrows
- "Clean white background, blueprint style, technical drawing"

### Step-by-Step Prompt Guidelines
[GENERATE_STEPS: garment] — The system generates 5 images automatically. You do NOT need to write prompts for each step. Just provide the garment type.

### CRITICAL: ALWAYS respect the user's specific requests
If the user specifies a color (e.g., "black agbada"), you MUST include that exact color in your prompt. Never override the user's color preference with a default.

IMPORTANT: The prompt MUST describe a SINGLE garment on a SINGLE model. Never generate images with multiple figures, split views, or collages.

${_getUserTypePrompt(userType)}
''';
  }

  String _getUserTypePrompt(String userType) {
    switch (userType) {
      case 'tailor':
        return '''
## TAILORED FOR: TAILOR

You are speaking with a tailor/fashion entrepreneur on Desby OS. They have access to these features and you should reference them by name:

### Their Platform Features
- **Dashboard**: Overview of active orders, net revenue, bookings, urgent alerts
- **Order Management**: Create orders, accept/reject bookings, track order pipeline (Booking → Accepted → Materials in Transit → In Progress → Ready → Delivered)
- **Client Management**: Add clients (unified flow), view client profiles, order history, measurements, milestones, digital closet, garment architecture, portfolio
- **Apprentice Management**: Add apprentices, approve enrollment requests, assign tasks, grade submissions, track progress (skill badges, completion %), build curriculum (modules + lessons)
- **My Shop**: Set up shop, add products, manage portfolio, view public shop page
- **Pricing Setup**: Configure three-tier pricing — base stitching price, material cost, starting price
- **Marketplace**: Browse fabrics, add to cart, checkout via Flutterwave
- **Designs**: Upload designs to gallery, browse, save/favourite
- **Insights**: View analytics dashboard, detailed reports, AI-powered business insights
- **Messages**: Chat with clients, apprentices, and other tailors
- **Subscription**: Manage subscription plan

### How You Can Help Them
- **Pricing advice**: Give specific Naira ranges based on garment type, fabric, complexity, and their market positioning
- **Fabric selection**: Recommend fabrics based on garment type, client preferences, climate, and budget
- **Client management**: Advise on client communication, measurement taking, expectation setting
- **Order pipeline**: Help them understand where orders are and what to do next
- **Apprentice training**: Guide on curriculum building, task assignment, grading, mentorship
- **Business growth**: Marketing, pricing strategy, client retention, brand building for Nigerian market
- **Quality control**: Finishing techniques, fabric handling, garment construction tips
- **Logistics**: Explain Fez delivery system, rider summoning, delivery tracking
- **SEWING GUIDANCE**: When asked how to sew, construct, or make a specific garment:
  - Provide step-by-step construction instructions (cutting → assembly → finishing)
  - Explain seam types, stitch choices, and pressing techniques for the specific fabric
  - Recommend needle sizes, thread types, and machine settings
  - Describe pattern layout and cutting directions
  - When they want to SEE the construction, use [GENERATE_SEWING_GUIDE: garment | step] for a specific step diagram
  - When they want a FULL VISUAL GUIDE of the construction process, use [GENERATE_STEPS: garment] for 5 sequential step images
  - Be specific about Nigerian/African garment construction (agbada joining, senator collar technique, kaftan embroidery placement)

### Business Context
- They run a tailoring business in Nigeria (or African market)
- They need to balance quality with profitability
- Time management is critical — help them prioritize
- Client satisfaction drives repeat business and referrals
- Apprentices are an investment — guide them to train effectively

Be a business partner as much as a fashion advisor. Think about profitability, client satisfaction, and brand building.
''';
      case 'client':
        return '''
## TAILORED FOR: FASHION CLIENT

You are speaking with someone using Desby OS to find tailoring services and manage their fashion journey. They have access to these features and you should reference them by name:

### Their Platform Features
- **Find Tailor**: Discover tailors using two modes — Uber (map-based, shows nearby tailors) or Gallery (browse by portfolio/style). View tailor profiles, availability, and reviews.
- **Booking Cart**: Select garment type, fabric, color, upload material photo, set measurements, configure delivery options
- **AI Body Scan**: Take front + side photos (dual-mode, 1-3cm accuracy) or single photo (3-8cm accuracy) to automatically extract body measurements. Results stored in Measurement Profile.
- **Measurement Profile**: View, edit, and manage saved measurements. Reusable across all orders.
- **Measurement Explorer**: Visual tool to explore and understand what each measurement means
- **Orders**: View all orders, track order status through the pipeline (Booking → Accepted → Materials in Transit → In Progress → Ready → Delivered)
- **Delivery Tracking**: Real-time Fez delivery tracking on a live map with GPS
- **Virtual Try-On**: Upload a garment photo and see how it looks on your body using AI
- **Design Gallery**: Browse tailors' designs, save/favourite, view details
- **Checkout**: Pay via Flutterwave (card, mobile money, bank transfer)
- **Reviews**: Submit reviews and ratings for tailors after order completion
- **Digital Closet**: Saved garment assets and snapshots from completed orders
- **Garment Architecture**: Design & fit plans for active orders
- **Live Milestones**: Real-time project status updates
- **Portfolio**: Project highlights and visuals collection
- **Messages**: Chat directly with your tailor

### How You Can Help Them
- **Finding a tailor**: Guide them to use Find Tailor, explain the difference between Uber and Gallery modes
- **Style advice**: Recommend styles based on body shape, occasion, budget, and climate
- **Fabric guidance**: Explain fabric properties, suitability, and what to tell their tailor
- **Measurement help**: Explain how to use AI Body Scan or take manual measurements
- **Order tracking**: Help them understand order pipeline stages and what each means
- **Budget planning**: Give realistic pricing expectations for different garment types
- **Care instructions**: Advise on fabric care and garment maintenance
- **What to expect**: Explain the tailoring process, timelines, and how to communicate with their tailor

### Booking Flow
When they want to order:
1. Find a tailor (Find Tailor → Uber or Gallery mode)
2. View tailor profile and availability
3. Add to Booking Cart (select garment, fabric, color, or upload material)
4. Set measurements (use AI Body Scan or enter manually)
5. Get price estimation
6. Checkout via Flutterwave
7. Track delivery via Fez

Be supportive and help them feel confident about their fashion choices.
''';
      case 'apprentice':
        return '''
## TAILORED FOR: APPRENTICE TAILOR

You are speaking with someone learning the tailoring craft through Desby OS's Apprenticeship Academy. They have access to these features and you should reference them by name:

### Their Platform Features
- **Dashboard**: Overview of learning sync %, skill badges earned, assigned mentor, recent tasks, curriculum progress
- **Tasks**: View assigned tasks with descriptions, due dates, and status (pending → submitted → under review → completed). Submit completed tasks for grading.
- **Curriculum**: Browse learning modules organized by skill area. Each module has lessons with content, examples, and practice exercises.
- **Progress**: Track overall completion %, skill badges earned, task completion history
- **Mentors**: View assigned mentor information with direct chat access for questions and guidance
- **Task Submission**: Upload completed work with photos/descriptions for mentor review
- **Task Grading**: View grades and feedback from mentor on submitted tasks
- **Lesson Detail**: View individual lesson content with examples and practice tips
- **Messages**: Chat with mentor and other apprentices

### Their Learning Journey
1. **Onboarding**: First-time setup wizard to configure their learning goals
2. **Curriculum**: Browse modules (e.g., Measurement Taking, Pattern Drafting, Sewing Basics, Fabric Knowledge, Finishing Techniques)
3. **Tasks**: Complete assigned tasks from mentor, submit for review
4. **Grading**: Mentor reviews and grades submissions with feedback
5. **Progress**: Earn skill badges as they complete modules and tasks
6. **Mentorship**: Direct chat with assigned mentor for questions and guidance

### How You Can Help Them
- **Technique explanation**: Break down tailoring techniques into simple, step-by-step instructions
- **Measurement practice**: Guide them on taking accurate measurements (chest, waist, hips, etc.)
- **Pattern drafting**: Explain pattern creation, dart placement, seam allowances
- **Sewing basics**: Machine operation, stitch types, thread tension, bobbin setup
- **Fabric knowledge**: Identifying fabric types, grain direction, cutting techniques
- **Finishing**: Hemming, pressing, buttonhole creation, final touches
- **Visual learning**: When they want to SEE construction, use [GENERATE_SEWING_GUIDE: garment | step] for specific diagrams, or [GENERATE_STEPS: garment] for a full step-by-step visual guide
- **Curriculum questions**: Help them understand lesson content and practice exercises
- **Motivation**: Encourage them, celebrate progress, help them stay on track
- **Task help**: Guide them on how to approach assigned tasks and what mentors look for

### Skill Areas (common curriculum modules)
- Measurement Taking & Body Analysis
- Pattern Drafting & Design
- Sewing Machine Operation
- Fabric Identification & Handling
- Cutting & Assembly
- Finishing & Pressing
- Quality Control
- Business Basics (for future tailoring business)

Be a patient mentor. Use simple language and build their confidence. Celebrate their progress.
''';
      case 'fabric_seller':
        return '''
## TAILORED FOR: FABRIC MERCHANT

You are speaking with a fabric seller/merchant on Desby OS's Fabric Marketplace. They have access to these features and you should reference them by name:

### Their Platform Features
- **Dashboard**: Overview of total GMV (gross merchandise value), order count, total SKUs, average rating, pending shipments, recent uploads with popularity scores
- **Fabric Upload**: Upload new fabric listings with images, name, description, price per yard, category, color, material type, minimum order quantity
- **Inventory Management**: View all SKUs, update stock levels, monitor popularity, manage availability
- **Orders**: View received orders, process them, dispatch via Fez logistics (Call Rider button)
- **Merchant Wallet**: View balance, transaction history, request payouts, manage earnings
- **Marketplace**: Browse own and other sellers' fabrics, view fabric details, pricing
- **Seller Portfolio**: Public-facing showcase of their fabric collection
- **Messages**: Chat with buyers (tailors and clients)
- **Subscription**: Manage subscription plan

### Order Fulfillment Flow
1. Buyer places order (fabric + quantity)
2. Seller receives order notification
3. Seller processes and prepares the fabric
4. Seller marks the order READY; a Fez rider is dispatched only at that point
5. Real-time delivery tracking for buyer
6. Buyer confirms receipt
7. Payment released to merchant wallet

### How You Can Help Them
- **Product descriptions**: Write compelling fabric descriptions that highlight quality, texture, use cases
- **Pricing strategy**: Advise on competitive pricing based on fabric type, quality, and market demand
- **Inventory management**: Tips on stock levels, restocking, seasonal planning
- **Marketplace optimization**: How to attract more buyers, improve listings, get better visibility
- **Photography tips**: How to photograph fabrics for listings (lighting, angles, close-ups)
- **Customer service**: Responding to buyer inquiries, handling complaints, building relationships
- **Fabric knowledge**: Storage, care, handling different fabric types
- **Business growth**: Expanding product range, targeting tailors vs clients, seasonal trends
- **Logistics**: Understanding Fez delivery, packaging, dispatch timing
- **Wallet/finance**: Managing earnings, payout scheduling, transaction tracking

### Fabric Categories (common on marketplace)
- Ankara (wax prints)
- Lace (Swiss, voille, cord)
- Aso-Oke (handwoven)
- George
- Damask
- Silk & Chiffon
- Cotton & Linen
- Velvet
- Kitenge

Think like a business partner who understands the Nigerian fabric market. Help them maximize sales and build a loyal customer base.
''';
      default:
        return '''
## TAILORED FOR: GENERAL USER
Help this Desby OS user with any fashion, tailoring, or platform-related questions. Guide them to the appropriate features based on their needs.
''';
    }
  }

  static final _imageIntentPatterns = [
    RegExp(
      r'(show|generate|create|make|draw|design|visualiz|visuali[sz]e)\s+(me\s+)?(an?\s+)?(image|photo|picture|sketch|design|visual|mock\s*up|reference)',
      caseSensitive: false,
    ),
    RegExp(
      r'i\s+(want|need)\s+(to\s+see|an?\s+image|a\s+design|a\s+picture)',
      caseSensitive: false,
    ),
    RegExp(
      r'(what|how)\s+(does|would)\s+.+\s+look\s+(like|on)',
      caseSensitive: false,
    ),
    RegExp(
      r'(show|send)\s+me\s+(a\s+)?(pic|image|photo|design|sketch|visual)',
      caseSensitive: false,
    ),
    RegExp(
      r'(agbada|senator|kaftan|gown|dress|suit|ankara|lace)\s+(design|style|image|picture|photo|sketch)',
      caseSensitive: false,
    ),
    RegExp(
      r'(pattern|cutting|sewing|construction|layout)\s+(diagram|guide|illustration|image|visual)',
      caseSensitive: false,
    ),
  ];

  bool _isImageRequest(String message) {
    return _imageIntentPatterns.any((p) => p.hasMatch(message));
  }

  String _buildImagePrompt(String userMessage) {
    final lower = userMessage.toLowerCase();

    // Detect garment type
    String garment;
    String fabricDetail;
    String styleDetail;

    if (lower.contains('agbada')) {
      garment = 'flowing Agbada robe with wide kimono-style sleeves';
      fabricDetail =
          'premium damask or aso-oke fabric with geometric embroidery on the neckline, cuffs, and chest panel';
      styleDetail = 'regal, commanding presence with elegant drape';
    } else if (lower.contains('senator')) {
      garment =
          'tailored Senator suit — fitted mandarin collar tunic with matching trousers';
      fabricDetail =
          'premium cotton with subtle piping detail along collar and front placket';
      styleDetail = 'clean modern lines, sharp tailoring';
    } else if (lower.contains('kaftan')) {
      garment =
          'luxurious African Kaftan with intricate hand-embroidered neckline';
      fabricDetail = 'silk or premium cotton with embroidered hem detailing';
      styleDetail = 'effortlessly elegant, relaxed refined fit';
    } else if (lower.contains('babariga') || lower.contains('babadiga')) {
      garment = 'majestic Babariga — layered Hausa royal robe';
      fabricDetail =
          'heavy aso-oke with concentric embroidery patterns on the chest';
      styleDetail = 'voluminous layered traditional royalty aesthetic';
    } else if (lower.contains('boubou')) {
      garment =
          'flowing West African Boubou — wide flowing gown with embroidered neckline';
      fabricDetail =
          'luxurious bazin or damask fabric with intricate hand-embroidery';
      styleDetail = 'regal, flowing silhouette with wide sleeves';
    } else if (lower.contains('iro') || lower.contains('buba')) {
      garment =
          'traditional Yoruba Iro and Buba — wrapped wrapper with loose blouse';
      fabricDetail =
          'premium aso-oke or lace fabric with matching headwrap (gele)';
      styleDetail = 'elegant traditional Yoruba feminine silhouette';
    } else if (lower.contains('wrapper') ||
        lower.contains('wrapper') ||
        lower.contains('gele')) {
      garment = 'elegant African wrapper ensemble with matching headwrap';
      fabricDetail = 'premium George, lace, or Ankara fabric';
      styleDetail = 'graceful draping with traditional African elegance';
    } else if (lower.contains('bridal') || lower.contains('wedding')) {
      garment =
          'luxurious African bridal gown — fusion of traditional and modern';
      fabricDetail =
          'premium lace, chiffon, or silk with crystal and bead embellishments';
      styleDetail =
          'show-stopping bridal elegance, floor-length, cathedral train';
    } else if (lower.contains('ankara')) {
      garment = 'vibrant Ankara wax print fashion ensemble';
      fabricDetail = 'bold African wax print with geometric or floral patterns';
      styleDetail =
          'modern African fashion with traditional fabric, contemporary cut';
    } else if (lower.contains('gown') || lower.contains('dress')) {
      garment = 'elegant floor-length African fashion gown';
      fabricDetail = 'luxurious chiffon or lace with delicate embellishments';
      styleDetail = 'flowing silhouette, red-carpet worthy';
    } else if (lower.contains('suit')) {
      garment = 'bespoke tailored suit with peak lapels';
      fabricDetail = 'premium Italian wool with fine texture';
      styleDetail = 'sharp modern fit, structured shoulders';
    } else {
      garment = 'premium Nigerian fashion design';
      fabricDetail = 'luxurious fabric with handcrafted embroidery details';
      styleDetail = 'contemporary African fashion with traditional influence';
    }

    // Extract user-specified color — respect what they asked for
    final color = _extractColor(lower);

    if (lower.contains('pattern') ||
        lower.contains('cutting') ||
        lower.contains('sewing') ||
        lower.contains('construction')) {
      return 'Technical fashion illustration: pattern layout and construction guide for $garment in $color. '
          'Clean flat pattern pieces on white background, precise measurement annotations, '
          'dotted fold lines, solid seam allowance lines, grain arrows, notch markers, '
          'professional technical drawing, fashion construction diagram, single view, '
          'clean crisp lines, blueprint style, high resolution. '
          'Negative: blurry, low quality, multiple views, collage, watermark, text';
    }

    return '$garment in $color, $fabricDetail. $styleDetail. '
        'Single confident Nigerian model in professional fashion studio, seamless background, '
        'editorial fashion photography, soft studio lighting with dramatic key light, '
        'sharp focus on garment details and fabric texture, Vogue Africa editorial quality, '
        'full-body shot, photorealistic, 8K detail. '
        'Negative: blurry, low quality, deformed, disfigured, extra limbs, bad anatomy, '
        'watermark, text, logo, multiple people, multiple figures, collage, split image';
  }

  /// Extract color from user message — respects their specific request.
  /// Uses word boundary matching to avoid false positives (e.g. "dress" matching "red").
  String _extractColor(String lower) {
    // Split into words for boundary-safe matching
    final words = lower.split(RegExp(r'\s+'));

    bool hasWord(String target) =>
        words.any((w) => w == target || w.startsWith(target));
    bool hasAny(List<String> targets) => targets.any(hasWord);

    if (hasWord('black'))
      return 'elegant black fabric with matching black embroidery';
    if (hasWord('white'))
      return 'pristine white fabric with tonal white embroidery';
    if (hasWord('cream')) return 'rich cream fabric with gold embroidery';
    if (hasWord('gold'))
      return 'luxurious gold fabric with metallic embroidery';
    if (hasWord('navy')) return 'navy blue fabric with tonal embroidery';
    if (hasWord('blue')) return 'deep royal blue fabric with gold embroidery';
    if (hasAny(['green', 'emerald']))
      return 'emerald green fabric with gold thread embroidery';
    if (hasAny(['red', 'ruby']))
      return 'deep ruby red fabric with gold embroidery';
    if (hasAny(['burgundy', 'wine']))
      return 'burgundy wine fabric with tonal embroidery';
    if (hasAny(['purple', 'violet']))
      return 'rich purple fabric with gold embroidery';
    if (hasWord('brown')) return 'chocolate brown fabric with tan embroidery';
    if (hasWord('pink')) return 'blush pink fabric with rose gold embroidery';
    if (hasAny(['yellow', 'mustard']))
      return 'mustard yellow fabric with brown embroidery';
    if (hasWord('orange')) return 'burnt orange fabric with gold embroidery';
    if (hasAny(['grey', 'gray']))
      return 'charcoal grey fabric with silver embroidery';
    if (hasWord('silver')) return 'metallic silver fabric with grey embroidery';
    if (hasAny(['beige', 'tan']))
      return 'warm beige fabric with brown embroidery';
    if (hasWord('maroon')) return 'deep maroon fabric with gold embroidery';
    if (hasAny(['teal', 'turquoise']))
      return 'rich teal fabric with gold embroidery';
    if (hasWord('coral')) return 'coral fabric with gold embroidery';
    if (hasWord('lavender')) return 'lavender fabric with silver embroidery';
    if (hasAny(['olive', 'khaki']))
      return 'olive green fabric with brown embroidery';

    // No color specified — garment-appropriate default
    return 'royal blue fabric with gold embroidery';
  }

  /// Detect step-by-step construction request
  bool _isStepByStepRequest(String message) {
    final lower = message.toLowerCase();
    return RegExp(
      r'(step[\s-]by[\s-]step|full\s+guide|complete\s+guide|how\s+to\s+(sew|make|construct|build)\s+.+\s+(step|from\s+start|beginning))',
      caseSensitive: false,
    ).hasMatch(lower);
  }

  /// Detect sewing guide request (pattern/construction diagram)
  bool _isSewingGuideRequest(String message) {
    final lower = message.toLowerCase();
    return RegExp(
          r'(sew|stitch|construct|make|pattern|cutting|assembly|joining|hem|collar|cuff|sleeve|finishing|pressing|dart|seam|grain|layout|technical|diagram|illustration|blueprint)',
          caseSensitive: false,
        ).hasMatch(lower) &&
        RegExp(
          r'(show|see|visual|diagram|illustration|guide|layout|image|picture|draw|sketch)',
          caseSensitive: false,
        ).hasMatch(lower);
  }

  Future<String> sendMessage(
    String userMessage, {
    required String userType,
    Map<String, dynamic> context = const {},
    String? imageUrl,
  }) async {
    const uuid = Uuid();

    _history.add(
      ZoeMessage(
        id: uuid.v4(),
        role: 'user',
        content: userMessage,
        timestamp: DateTime.now(),
        imageUrl: imageUrl,
      ),
    );

    while (_history.length > _maxHistory) {
      _history.removeAt(0);
    }

    final recentMessages = _history.length > 10
        ? _history.sublist(_history.length - 10)
        : _history;

    final apiMessages = recentMessages
        .map((m) => {'role': m.role, 'content': m.content})
        .toList();

    final systemPrompt = _buildSystemPrompt(userType, context);

    // Detect image intent proactively
    final wantsImage = _isImageRequest(userMessage) && _imageService != null;
    final wantsSteps = _isStepByStepRequest(userMessage);
    final wantsSewingGuide = _isSewingGuideRequest(userMessage) && !wantsSteps;

    try {
      final reply = await _cluster.complete(
        systemPrompt: systemPrompt,
        messages: apiMessages,
      );

      String textContent = reply;
      List<String> imageUrls = [];

      // Parse all tags from the reply
      final allImageTags = RegExp(
        r'\[GENERATE_IMAGE:\s*(.+?)\]',
      ).allMatches(reply).toList();
      final stepsTagMatch = RegExp(
        r'\[GENERATE_STEPS:\s*(.+?)\]',
      ).firstMatch(reply);
      final sewingGuideTagMatch = RegExp(
        r'\[GENERATE_SEWING_GUIDE:\s*(.+?)\s*\|\s*(.+?)\]',
      ).firstMatch(reply);

      // Remove all tags from text
      textContent = reply
          .replaceAll(RegExp(r'\[GENERATE_IMAGE:\s*(.+?)\]'), '')
          .replaceAll(RegExp(r'\[GENERATE_STEPS:\s*(.+?)\]'), '')
          .replaceAll(
            RegExp(r'\[GENERATE_SEWING_GUIDE:\s*(.+?)\s*\|\s*(.+?)\]'),
            '',
          )
          .trim();

      if (_imageService != null) {
        // Mode: Step-by-step construction (generates 5 images)
        if (stepsTagMatch != null) {
          final garmentType = stepsTagMatch.group(1)!.trim();
          textContent =
              '$textContent\n\nGenerating $garmentType construction steps...';
          final steps = await _generateConstructionSteps(garmentType);
          imageUrls.addAll(steps);
        }
        // Mode: Sewing guide diagram
        else if (sewingGuideTagMatch != null) {
          final garmentType = sewingGuideTagMatch.group(1)!.trim();
          final stepFocus = sewingGuideTagMatch.group(2)!.trim();
          final prompt =
              'Technical fashion illustration: $stepFocus for $garmentType. '
              'Clean flat pattern pieces on white background, precise measurement annotations, '
              'dotted fold lines, solid seam allowance lines, grain arrows, notch markers, '
              'professional technical drawing, fashion construction diagram, single view, '
              'clean crisp lines, blueprint style, high resolution. '
              'Negative: blurry, low quality, multiple views, collage, watermark, text';
          final url = await _imageService.generateFashionConcept(prompt);
          if (url != null) imageUrls.add(url);
        }
        // Mode: Multiple [GENERATE_IMAGE] tags
        else if (allImageTags.isNotEmpty) {
          for (final tag in allImageTags) {
            final imagePrompt = tag.group(1)!;
            final url = await _imageService.generateFashionConcept(imagePrompt);
            if (url != null) imageUrls.add(url);
          }
        }
        // Mode: Proactive image detection (user asked but AI didn't tag)
        else if (wantsImage) {
          final imagePrompt = _buildImagePrompt(userMessage);
          final url = await _imageService.generateFashionConcept(imagePrompt);
          if (url != null) imageUrls.add(url);
        }
        // Mode: Sewing guide request without AI tag
        else if (wantsSewingGuide) {
          final garmentType = _extractGarmentType(userMessage);
          final prompt =
              'Technical fashion illustration: cutting layout and pattern guide for $garmentType. '
              'Clean flat pattern pieces on white background, precise measurement annotations, '
              'dotted fold lines, solid seam allowance lines, grain arrows, notch markers, '
              'professional technical drawing, fashion construction diagram, single view, '
              'clean crisp lines, blueprint style, high resolution. '
              'Negative: blurry, low quality, multiple views, collage, watermark, text';
          final url = await _imageService.generateFashionConcept(prompt);
          if (url != null) imageUrls.add(url);
        }
      }

      // Build messages: if multiple images, create separate messages per image
      if (imageUrls.length <= 1) {
        _history.add(
          ZoeMessage(
            id: uuid.v4(),
            role: 'assistant',
            content: textContent,
            timestamp: DateTime.now(),
            imageUrl: imageUrls.isNotEmpty ? imageUrls.first : null,
          ),
        );
      } else {
        // Multiple images: first message has text + first image, rest are image-only
        _history.add(
          ZoeMessage(
            id: uuid.v4(),
            role: 'assistant',
            content: textContent,
            timestamp: DateTime.now(),
            imageUrl: imageUrls.first,
          ),
        );
        for (int i = 1; i < imageUrls.length; i++) {
          _history.add(
            ZoeMessage(
              id: uuid.v4(),
              role: 'assistant',
              content: '',
              timestamp: DateTime.now(),
              imageUrl: imageUrls[i],
            ),
          );
        }
      }

      _saveMessages();
      return textContent;
    } catch (e) {
      debugPrint('[ZOE] Cluster error: $e');
      const fallback =
          'Sorry, I\'m having a brief connection issue. Give me a moment and try again — I\'m right here.';

      _history.add(
        ZoeMessage(
          id: uuid.v4(),
          role: 'assistant',
          content: fallback,
          timestamp: DateTime.now(),
        ),
      );

      _saveMessages();
      return fallback;
    }
  }

  /// Generate 5 sequential construction step images
  Future<List<String>> _generateConstructionSteps(String garmentType) async {
    if (_imageService == null) return [];

    final steps = [
      (
        'Cutting Layout',
        'pattern layout and cutting guide for $garmentType. Clean flat pattern pieces on white background, precise measurement annotations, dotted fold lines, solid seam allowance lines, grain arrows, notch markers, technical fashion illustration, blueprint style, high resolution',
      ),
      (
        'Assembly & Joining',
        'garment assembly and joining diagram for $garmentType. Step-by-step construction showing seam locations, stitch directions, assembly order arrows, numbered construction steps, technical fashion illustration, clean white background, blueprint style',
      ),
      (
        'Collar & Detail Work',
        'collar construction and detail work for $garmentType. Close-up technical illustration of collar attachment, cuff construction, placket finishing, pocket placement, measurement annotations, technical fashion illustration, blueprint style',
      ),
      (
        'Finishing & Hemming',
        'finishing techniques and hemming guide for $garmentType. Hem types, pressing guide, buttonhole placement, final finishing touches, measurement annotations, technical fashion illustration, clean white background, blueprint style',
      ),
      (
        'Completed Garment',
        'finished $garmentType technical flat sketch. Front and back view, all construction details visible, seam lines, topstitching, final garment specification sheet, technical fashion illustration, clean white background, professional flat sketch',
      ),
    ];

    final urls = <String>[];
    for (final (title, prompt) in steps) {
      try {
        final url = await _imageService.generateFashionConcept(prompt);
        if (url != null) urls.add(url);
      } catch (e) {
        debugPrint('[ZOE] Step generation failed for $title: $e');
      }
    }
    return urls;
  }

  /// Extract garment type from user message
  String _extractGarmentType(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('agbada')) return 'Agbada';
    if (lower.contains('senator')) return 'Senator suit';
    if (lower.contains('kaftan')) return 'Kaftan';
    if (lower.contains('babariga') || lower.contains('babadiga'))
      return 'Babariga';
    if (lower.contains('boubou')) return 'Boubou';
    if (lower.contains('iro') || lower.contains('buba')) return 'Iro and Buba';
    if (lower.contains('ankara')) return 'Ankara gown';
    if (lower.contains('gown') || lower.contains('dress')) return 'Gown';
    if (lower.contains('suit')) return 'Suit';
    if (lower.contains('shirt')) return 'Shirt';
    if (lower.contains('trouser') || lower.contains('pants')) return 'Trousers';
    return 'Garment';
  }
}
