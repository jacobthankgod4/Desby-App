import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/apprenticeship.dart';
import '../../domain/entities/apprentice_task.dart';
import '../../domain/entities/apprentice_module.dart';
import '../../domain/repositories/apprenticeship_repository.dart';
import '../models/apprentice_task_model.dart';

class FirebaseApprenticeshipRepository implements ApprenticeshipRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<Result<List<ApprenticeModule>>> getCurriculum() async {
    // ENRICHED MASTER-GRADE CURRICULUM
    return const Success([
      ApprenticeModule(
        id: 'module_1', title: 'The Professional Designer Dossier', orderIndex: 0,
        description: 'Professional ethics, client consultation, and the psychology of bespoke service.',
        lessonIds: ['l1', 'l2'],
      ),
      ApprenticeModule(
        id: 'module_2', title: 'Advanced Measurement Science', orderIndex: 1,
        description: 'Landmark identification, 3D postural analysis, and ergonomic fit theory.',
        lessonIds: ['l3', 'l4'],
      ),
      ApprenticeModule(
        id: 'module_3', title: 'Foundations of Bespoke Architecture', orderIndex: 2,
        description: 'Mastering grain lines, fabric behavior, and the physics of the human form.',
        lessonIds: ['l5', 'l6'],
      ),
      ApprenticeModule(
        id: 'module_4', title: 'The Art of the Canvas', orderIndex: 3,
        description: 'Full-canvas construction techniques using horsehair and linen internals.',
        lessonIds: ['l7', 'l8'],
      ),
      ApprenticeModule(
        id: 'module_5', title: 'Traditional Masterpieces', orderIndex: 4,
        description: 'Structural engineering for Agbada, Kaftan, and high-density traditional robes.',
        lessonIds: ['l9', 'l10'],
      ),
      ApprenticeModule(
        id: 'module_6', title: 'The Savile Row Silhouette', orderIndex: 5,
        description: 'Advanced jacket drafting, shoulder expression, and chest-piece manipulation.',
        lessonIds: ['l11', 'l12'],
      ),
      ApprenticeModule(
        id: 'module_7', title: 'Luxury Finishing & Milanese Detail', orderIndex: 6,
        description: 'The Milanese buttonhole, pick stitching, and invisible functional details.',
        lessonIds: ['l13', 'l14'],
      ),
      ApprenticeModule(
        id: 'module_8', title: 'Bridal & High-Density Draping', orderIndex: 7,
        description: 'Corsetry, internal bone structure, and managing heavy lace/embellishment.',
        lessonIds: ['l15'],
      ),
      ApprenticeModule(
        id: 'module_9', title: 'Industrial Engineering & Tools', orderIndex: 8,
        description: 'Machine maintenance, needle thermodynamics, and advanced tool calibration.',
        lessonIds: ['l16'],
      ),
      ApprenticeModule(
        id: 'module_10', title: 'The Master Business Blueprint', orderIndex: 9,
        description: 'Commercial costing, scaling a shop, and global procurement strategies.',
        lessonIds: ['l17'],
      ),
    ]);
  }

  @override
  Future<Result<List<ApprenticeLesson>>> getLessons(String moduleId) async {
    final Map<String, List<ApprenticeLesson>> lessonMap = {
      'module_1': [
        const ApprenticeLesson(id: 'l1', moduleId: 'module_1', title: 'The Anatomy of Consultation', orderIndex: 0, content: 'Learning how to guide a client through fabric selection without overwhelming their design intent.'),
        const ApprenticeLesson(id: 'l2', moduleId: 'module_1', title: 'Ethics of the Craft', orderIndex: 1, content: 'Confidentiality of measurements and the integrity of premium material sourcing.'),
      ],
      'module_2': [
        const ApprenticeLesson(id: 'l3', moduleId: 'module_2', title: 'Postural Landmark IDs', orderIndex: 0, content: 'Identifying the 12 key skeletal points for a perfect zero-gravity fit.'),
        const ApprenticeLesson(id: 'l4', moduleId: 'module_2', title: 'The Physics of Slope', orderIndex: 1, content: 'Compensating for low shoulders and forward neck posture in pattern drafting.'),
      ],
      'module_7': [
        const ApprenticeLesson(
          id: 'l13', moduleId: 'module_7', title: 'The Milanese Buttonhole', 
          orderIndex: 0, content: 'Step-by-step guide to the world most difficult hand-stitched buttonhole using silk gimp.',
          videoUrl: 'https://desby-os.storage/masterclasses/milanese_buttonhole.mp4'
        ),
      ]
    };
    return Success(lessonMap[moduleId] ?? []);
  }

  @override
  Future<Result<ApprenticeLesson>> getLessonById(String lessonId) async {
    // Universal Lesson Resolver
    return Success(ApprenticeLesson(
      id: lessonId, moduleId: 'dynamic', title: 'Mastering Technical Drafts', 
      orderIndex: 0, content: 'This lesson covers the high-density technical requirements for this module. Refer to your Master for physical swatches and calibrated tools.'
    ));
  }

  @override
  Future<Result<List<ApprenticeTask>>> getApprenticeTasks(String apprenticeshipId) async {
    return Success([
      ApprenticeTask(id: 't1', apprenticeshipId: apprenticeshipId, title: 'Draft a notched lapel', status: ApprenticeTaskStatus.todo, dueDate: DateTime.now().add(const Duration(days: 2)), description: 'Precisely draft a 3.5-inch notched lapel for a size 42R jacket.'),
      ApprenticeTask(id: 't2', apprenticeshipId: apprenticeshipId, title: 'Hand-stitch 10 buttonholes', status: ApprenticeTaskStatus.inProgress, dueDate: DateTime.now().add(const Duration(days: 1)), description: 'Complete 10 silk-twist buttonholes on a test swatch.'),
      ApprenticeTask(id: 't3', apprenticeshipId: apprenticeshipId, title: 'Block a structured collar', status: ApprenticeTaskStatus.todo, dueDate: DateTime.now().add(const Duration(days: 4)), description: 'Steam-block a horsehair canvas collar for a bespoke blazer.'),
    ]);
  }

  @override
  Future<Result<List<Apprenticeship>>> getApprenticeships(String tailorId) async {
    try {
      final snapshot = await _firestore.collection('apprenticeships').where('tailorId', isEqualTo: tailorId).get();
      return Success(snapshot.docs.map((doc) => _mapToApprenticeship(doc.id, doc.data())).toList());
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<Apprenticeship?>> getApprenticeship(String apprenticeId) async {
    try {
      final snapshot = await _firestore.collection('apprenticeships').where('apprenticeId', isEqualTo: apprenticeId).limit(1).get();
      if (snapshot.docs.isEmpty) return const Success(null);
      return Success(_mapToApprenticeship(snapshot.docs.first.id, snapshot.docs.first.data()));
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<Apprenticeship>> createApprenticeship(Apprenticeship apprenticeship) async {
    try {
      await _firestore.collection('apprenticeships').doc(apprenticeship.id).set(_mapFromApprenticeship(apprenticeship));
      return Success(apprenticeship);
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<Apprenticeship>> updateApprenticeship(Apprenticeship apprenticeship) async {
    try {
      await _firestore.collection('apprenticeships').doc(apprenticeship.id).update(_mapFromApprenticeship(apprenticeship));
      return Success(apprenticeship);
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<ApprenticeTask>> createTask(ApprenticeTask task) async {
    try {
      final model = ApprenticeTaskModel.fromEntity(task);
      await _firestore.collection('apprentice_tasks').doc(model.id).set(model.toJson());
      return Success(task);
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<ApprenticeTask>> updateTask(ApprenticeTask task) async {
    try {
      final model = ApprenticeTaskModel.fromEntity(task);
      await _firestore.collection('apprentice_tasks').doc(model.id).update(model.toJson());
      return Success(task);
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  Apprenticeship _mapToApprenticeship(String id, Map<String, dynamic> data) {
    return Apprenticeship(
      id: id,
      tailorId: data['tailorId'] as String,
      apprenticeId: data['apprenticeId'] as String,
      status: _parseApprenticeshipStatus(data['status'] as String),
      progress: (data['progress'] as num).toDouble(),
      startDate: (data['startDate'] as Timestamp).toDate(),
      skillIds: List<String>.from(data['skillIds'] as List),
    );
  }

  Map<String, dynamic> _mapFromApprenticeship(Apprenticeship app) {
    return {
      'tailorId': app.tailorId,
      'apprenticeId': app.apprenticeId,
      'status': app.status.name,
      'progress': app.progress,
      'startDate': app.startDate,
      'skillIds': app.skillIds,
    };
  }

  ApprenticeshipStatus _parseApprenticeshipStatus(String status) {
    return ApprenticeshipStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => ApprenticeshipStatus.awaitingMasterApproval,
    );
  }
}
