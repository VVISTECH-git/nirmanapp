// lib/models/models.dart
// All NirmanApp data models

class UserProfile {
  final String id;
  final String email;
  final String? fullName;
  final String? phone;
  final String? avatarUrl;
  final bool isSuperAdmin;
  final String accessStatus; // pending, approved, rejected
  final DateTime? requestedAt;
  final DateTime? approvedAt;

  UserProfile({
    required this.id,
    required this.email,
    this.fullName,
    this.phone,
    this.avatarUrl,
    this.isSuperAdmin = false,
    this.accessStatus = 'pending',
    this.requestedAt,
    this.approvedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'],
    email: json['email'],
    fullName: json['full_name'],
    phone: json['phone'],
    avatarUrl: json['avatar_url'],
    isSuperAdmin: json['is_super_admin'] ?? false,
    accessStatus: json['access_status'] ?? 'pending',
    requestedAt: json['requested_at'] != null ? DateTime.parse(json['requested_at']) : null,
    approvedAt: json['approved_at'] != null ? DateTime.parse(json['approved_at']) : null,
  );

  bool get isApproved => accessStatus == 'approved';
  bool get isPending => accessStatus == 'pending';
  String get displayName => fullName ?? email.split('@').first;
  String get initials {
    if (fullName != null && fullName!.isNotEmpty) {
      final parts = fullName!.trim().split(' ');
      if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      return fullName![0].toUpperCase();
    }
    return email[0].toUpperCase();
  }
}

class Project {
  final String id;
  final String name;
  final String? description;
  final String? address;
  final String? city;
  final String state;
  final int totalBudgetPaise;
  final DateTime? startDate;
  final DateTime? expectedEndDate;
  final DateTime? actualEndDate;
  final String? coverImageUrl;
  final bool isPublic;
  final String ownerId;
  final DateTime createdAt;
  // Computed from view
  final int? totalSpentPaise;
  final int? openTasks;
  final int? overdueTasks;
  final int? openIssues;
  final int? teamSize;

  Project({
    required this.id,
    required this.name,
    this.description,
    this.address,
    this.city,
    this.state = 'Telangana',
    this.totalBudgetPaise = 0,
    this.startDate,
    this.expectedEndDate,
    this.actualEndDate,
    this.coverImageUrl,
    this.isPublic = false,
    required this.ownerId,
    required this.createdAt,
    this.totalSpentPaise,
    this.openTasks,
    this.overdueTasks,
    this.openIssues,
    this.teamSize,
  });

  factory Project.fromJson(Map<String, dynamic> json) => Project(
    id: json['id'],
    name: json['name'],
    description: json['description'],
    address: json['address'],
    city: json['city'],
    state: json['state'] ?? 'Telangana',
    totalBudgetPaise: json['total_budget_paise'] ?? 0,
    startDate: json['start_date'] != null ? DateTime.parse(json['start_date']) : null,
    expectedEndDate: json['expected_end_date'] != null ? DateTime.parse(json['expected_end_date']) : null,
    actualEndDate: json['actual_end_date'] != null ? DateTime.parse(json['actual_end_date']) : null,
    coverImageUrl: json['cover_image_url'],
    isPublic: json['is_public'] ?? false,
    ownerId: json['owner_id'],
    createdAt: DateTime.parse(json['created_at']),
    totalSpentPaise: json['total_spent_paise'],
    openTasks: json['open_tasks'],
    overdueTasks: json['overdue_tasks'],
    openIssues: json['open_issues'],
    teamSize: json['team_size'],
  );

  double get totalBudgetLakhs => totalBudgetPaise / 10000000;
  double get totalSpentLakhs => (totalSpentPaise ?? 0) / 10000000;
  double get progressPercent => totalBudgetPaise > 0
      ? ((totalSpentPaise ?? 0) / totalBudgetPaise * 100).clamp(0, 100)
      : 0;
}

class Phase {
  final String id;
  final String projectId;
  final String name;
  final String? description;
  final int orderIndex;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? actualStartDate;
  final DateTime? actualEndDate;
  final int budgetPaise;
  final String color;
  // Computed
  final int? totalTasks;
  final int? doneTasks;
  final double? progressPct;
  final int? spentPaise;

  Phase({
    required this.id,
    required this.projectId,
    required this.name,
    this.description,
    required this.orderIndex,
    this.status = 'upcoming',
    this.startDate,
    this.endDate,
    this.actualStartDate,
    this.actualEndDate,
    this.budgetPaise = 0,
    this.color = '#378ADD',
    this.totalTasks,
    this.doneTasks,
    this.progressPct,
    this.spentPaise,
  });

  factory Phase.fromJson(Map<String, dynamic> json) => Phase(
    id: json['id'],
    projectId: json['project_id'],
    name: json['name'],
    description: json['description'],
    orderIndex: json['order_index'] ?? 0,
    status: json['status'] ?? 'upcoming',
    startDate: json['start_date'] != null ? DateTime.parse(json['start_date']) : null,
    endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
    actualStartDate: json['actual_start_date'] != null ? DateTime.parse(json['actual_start_date']) : null,
    actualEndDate: json['actual_end_date'] != null ? DateTime.parse(json['actual_end_date']) : null,
    budgetPaise: json['budget_paise'] ?? 0,
    color: json['color'] ?? '#378ADD',
    totalTasks: json['total_tasks'],
    doneTasks: json['done_tasks'],
    progressPct: json['progress_pct']?.toDouble(),
    spentPaise: json['spent_paise'],
  );
}

class PlanningItem {
  final String id;
  final String projectId;
  final String phaseId;
  final String name;
  final String itemType;
  final String status;
  final String? assignedTo;
  final String? assignedToName;
  final DateTime? dueDate;
  final DateTime? completedDate;
  final String? notes;
  final int orderIndex;

  PlanningItem({
    required this.id,
    required this.projectId,
    required this.phaseId,
    required this.name,
    required this.itemType,
    this.status = 'todo',
    this.assignedTo,
    this.assignedToName,
    this.dueDate,
    this.completedDate,
    this.notes,
    this.orderIndex = 0,
  });

  factory PlanningItem.fromJson(Map<String, dynamic> json) => PlanningItem(
    id: json['id'],
    projectId: json['project_id'],
    phaseId: json['phase_id'],
    name: json['name'],
    itemType: json['item_type'] ?? 'other',
    status: json['status'] ?? 'todo',
    assignedTo: json['assigned_to'],
    assignedToName: json['assigned_to_name'],
    dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
    completedDate: json['completed_date'] != null ? DateTime.parse(json['completed_date']) : null,
    notes: json['notes'],
    orderIndex: json['order_index'] ?? 0,
  );
}

class Task {
  final String id;
  final String projectId;
  final String? phaseId;
  final String? phaseName;
  final String title;
  final String? description;
  final String status;
  final String priority;
  final String? assignedTo;
  final String? assignedToName;
  final String? createdBy;
  final DateTime? dueDate;
  final DateTime? completedDate;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.projectId,
    this.phaseId,
    this.phaseName,
    required this.title,
    this.description,
    this.status = 'todo',
    this.priority = 'medium',
    this.assignedTo,
    this.assignedToName,
    this.createdBy,
    this.dueDate,
    this.completedDate,
    required this.createdAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'],
    projectId: json['project_id'],
    phaseId: json['phase_id'],
    phaseName: json['phase_name'],
    title: json['title'],
    description: json['description'],
    status: json['status'] ?? 'todo',
    priority: json['priority'] ?? 'medium',
    assignedTo: json['assigned_to'],
    assignedToName: json['assigned_to_name'],
    createdBy: json['created_by'],
    dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
    completedDate: json['completed_date'] != null ? DateTime.parse(json['completed_date']) : null,
    createdAt: DateTime.parse(json['created_at']),
  );

  bool get isOverdue => dueDate != null && dueDate!.isBefore(DateTime.now()) && status != 'done';
}

class Issue {
  final String id;
  final String projectId;
  final String? phaseId;
  final String? phaseName;
  final String title;
  final String? description;
  final String status;
  final String priority;
  final String? reportedBy;
  final String? reportedByName;
  final String? assignedTo;
  final String? assignedToName;
  final DateTime? resolvedAt;
  final DateTime? dueDate;
  final DateTime createdAt;

  Issue({
    required this.id,
    required this.projectId,
    this.phaseId,
    this.phaseName,
    required this.title,
    this.description,
    this.status = 'open',
    this.priority = 'medium',
    this.reportedBy,
    this.reportedByName,
    this.assignedTo,
    this.assignedToName,
    this.resolvedAt,
    this.dueDate,
    required this.createdAt,
  });

  factory Issue.fromJson(Map<String, dynamic> json) => Issue(
    id: json['id'],
    projectId: json['project_id'],
    phaseId: json['phase_id'],
    phaseName: json['phase_name'],
    title: json['title'],
    description: json['description'],
    status: json['status'] ?? 'open',
    priority: json['priority'] ?? 'medium',
    reportedBy: json['reported_by'],
    reportedByName: json['reported_by_name'],
    assignedTo: json['assigned_to'],
    assignedToName: json['assigned_to_name'],
    resolvedAt: json['resolved_at'] != null ? DateTime.parse(json['resolved_at']) : null,
    dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
    createdAt: DateTime.parse(json['created_at']),
  );
}

class DailyLog {
  final String id;
  final String projectId;
  final String? phaseId;
  final DateTime logDate;
  final String? loggedBy;
  final String? loggedByName;
  final String? weather;
  final int workersPresent;
  final String? workSummary;
  final String? materialsUsed;
  final String? issuesNoted;
  final String? nextDayPlan;
  final DateTime createdAt;
  final List<AppDocument> documents;

  DailyLog({
    required this.id,
    required this.projectId,
    this.phaseId,
    required this.logDate,
    this.loggedBy,
    this.loggedByName,
    this.weather,
    this.workersPresent = 0,
    this.workSummary,
    this.materialsUsed,
    this.issuesNoted,
    this.nextDayPlan,
    required this.createdAt,
    this.documents = const [],
  });

  factory DailyLog.fromJson(Map<String, dynamic> json) => DailyLog(
    id: json['id'],
    projectId: json['project_id'],
    phaseId: json['phase_id'],
    logDate: DateTime.parse(json['log_date']),
    loggedBy: json['logged_by'],
    loggedByName: json['logged_by_name'],
    weather: json['weather'],
    workersPresent: json['workers_present'] ?? 0,
    workSummary: json['work_summary'],
    materialsUsed: json['materials_used'],
    issuesNoted: json['issues_noted'],
    nextDayPlan: json['next_day_plan'],
    createdAt: DateTime.parse(json['created_at']),
  );
}

class Contractor {
  final String id;
  final String projectId;
  final String? userId;
  final String name;
  final String? role;
  final String? phone;
  final String? email;
  final int dailyRatePaise;
  final int contractAmountPaise;
  final bool isActive;
  final DateTime? joinedDate;
  final String? notes;

  Contractor({
    required this.id,
    required this.projectId,
    this.userId,
    required this.name,
    this.role,
    this.phone,
    this.email,
    this.dailyRatePaise = 0,
    this.contractAmountPaise = 0,
    this.isActive = true,
    this.joinedDate,
    this.notes,
  });

  factory Contractor.fromJson(Map<String, dynamic> json) => Contractor(
    id: json['id'],
    projectId: json['project_id'],
    userId: json['user_id'],
    name: json['name'],
    role: json['role'],
    phone: json['phone'],
    email: json['email'],
    dailyRatePaise: json['daily_rate_paise'] ?? 0,
    contractAmountPaise: json['contract_amount_paise'] ?? 0,
    isActive: json['is_active'] ?? true,
    joinedDate: json['joined_date'] != null ? DateTime.parse(json['joined_date']) : null,
    notes: json['notes'],
  );

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name[0].toUpperCase();
  }
}

class Material {
  final String id;
  final String projectId;
  final String? phaseId;
  final String name;
  final String? brand;
  final double? quantity;
  final String? unit;
  final int unitPricePaise;
  final int totalPricePaise;
  final String? supplier;
  final DateTime? deliveryDate;
  final String? notes;
  final DateTime createdAt;

  Material({
    required this.id,
    required this.projectId,
    this.phaseId,
    required this.name,
    this.brand,
    this.quantity,
    this.unit,
    this.unitPricePaise = 0,
    this.totalPricePaise = 0,
    this.supplier,
    this.deliveryDate,
    this.notes,
    required this.createdAt,
  });

  factory Material.fromJson(Map<String, dynamic> json) => Material(
    id: json['id'],
    projectId: json['project_id'],
    phaseId: json['phase_id'],
    name: json['name'],
    brand: json['brand'],
    quantity: json['quantity']?.toDouble(),
    unit: json['unit'],
    unitPricePaise: json['unit_price_paise'] ?? 0,
    totalPricePaise: json['total_price_paise'] ?? 0,
    supplier: json['supplier'],
    deliveryDate: json['delivery_date'] != null ? DateTime.parse(json['delivery_date']) : null,
    notes: json['notes'],
    createdAt: DateTime.parse(json['created_at']),
  );
}

class Expense {
  final String id;
  final String projectId;
  final String? phaseId;
  final String? phaseName;
  final String title;
  final String? description;
  final String category;
  final int amountPaise;
  final int gstPaise;
  final DateTime expenseDate;
  final String? paidBy;
  final String? receiptUrl;
  final DateTime createdAt;

  Expense({
    required this.id,
    required this.projectId,
    this.phaseId,
    this.phaseName,
    required this.title,
    this.description,
    this.category = 'misc',
    required this.amountPaise,
    this.gstPaise = 0,
    required this.expenseDate,
    this.paidBy,
    this.receiptUrl,
    required this.createdAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
    id: json['id'],
    projectId: json['project_id'],
    phaseId: json['phase_id'],
    phaseName: json['phase_name'],
    title: json['title'],
    description: json['description'],
    category: json['category'] ?? 'misc',
    amountPaise: json['amount_paise'] ?? 0,
    gstPaise: json['gst_paise'] ?? 0,
    expenseDate: DateTime.parse(json['expense_date']),
    paidBy: json['paid_by'],
    receiptUrl: json['receipt_url'],
    createdAt: DateTime.parse(json['created_at']),
  );

  int get totalPaise => amountPaise + gstPaise;
}

class Payment {
  final String id;
  final String projectId;
  final String contractorId;
  final String? contractorName;
  final String title;
  final String? description;
  final int amountPaise;
  final String status;
  final String? milestoneDescription;
  final DateTime? dueDate;
  final DateTime? paidDate;
  final String? receiptUrl;
  final DateTime createdAt;

  Payment({
    required this.id,
    required this.projectId,
    required this.contractorId,
    this.contractorName,
    required this.title,
    this.description,
    required this.amountPaise,
    this.status = 'pending',
    this.milestoneDescription,
    this.dueDate,
    this.paidDate,
    this.receiptUrl,
    required this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
    id: json['id'],
    projectId: json['project_id'],
    contractorId: json['contractor_id'],
    contractorName: json['contractor_name'],
    title: json['title'],
    description: json['description'],
    amountPaise: json['amount_paise'] ?? 0,
    status: json['status'] ?? 'pending',
    milestoneDescription: json['milestone_description'],
    dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
    paidDate: json['paid_date'] != null ? DateTime.parse(json['paid_date']) : null,
    receiptUrl: json['receipt_url'],
    createdAt: DateTime.parse(json['created_at']),
  );
}

class AppDocument {
  final String id;
  final String projectId;
  final String? phaseId;
  final String? taskId;
  final String? planningItemId;
  final String? issueId;
  final String? dailyLogId;
  final String title;
  final String docType;
  final String fileUrl;
  final String? fileName;
  final int? fileSizeBytes;
  final String? mimeType;
  final String? thumbnailUrl;
  final String? uploadedBy;
  final String? uploadedByName;
  final String? notes;
  final DateTime createdAt;

  AppDocument({
    required this.id,
    required this.projectId,
    this.phaseId,
    this.taskId,
    this.planningItemId,
    this.issueId,
    this.dailyLogId,
    required this.title,
    this.docType = 'misc',
    required this.fileUrl,
    this.fileName,
    this.fileSizeBytes,
    this.mimeType,
    this.thumbnailUrl,
    this.uploadedBy,
    this.uploadedByName,
    this.notes,
    required this.createdAt,
  });

  factory AppDocument.fromJson(Map<String, dynamic> json) => AppDocument(
    id: json['id'],
    projectId: json['project_id'],
    phaseId: json['phase_id'],
    taskId: json['task_id'],
    planningItemId: json['planning_item_id'],
    issueId: json['issue_id'],
    dailyLogId: json['daily_log_id'],
    title: json['title'],
    docType: json['doc_type'] ?? 'misc',
    fileUrl: json['file_url'],
    fileName: json['file_name'],
    fileSizeBytes: json['file_size_bytes'],
    mimeType: json['mime_type'],
    thumbnailUrl: json['thumbnail_url'],
    uploadedBy: json['uploaded_by'],
    uploadedByName: json['uploaded_by_name'],
    notes: json['notes'],
    createdAt: DateTime.parse(json['created_at']),
  );

  bool get isImage => mimeType?.startsWith('image/') ?? false;
  bool get isPdf => mimeType == 'application/pdf';
  String get fileSizeDisplay {
    if (fileSizeBytes == null) return '';
    if (fileSizeBytes! < 1024) return '${fileSizeBytes}B';
    if (fileSizeBytes! < 1024 * 1024) return '${(fileSizeBytes! / 1024).toStringAsFixed(0)} KB';
    return '${(fileSizeBytes! / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class AppNotification {
  final String id;
  final String userId;
  final String? projectId;
  final String title;
  final String? body;
  final String? type;
  final String? referenceId;
  final String? referenceType;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    this.projectId,
    required this.title,
    this.body,
    this.type,
    this.referenceId,
    this.referenceType,
    this.isRead = false,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
    id: json['id'],
    userId: json['user_id'],
    projectId: json['project_id'],
    title: json['title'],
    body: json['body'],
    type: json['type'],
    referenceId: json['reference_id'],
    referenceType: json['reference_type'],
    isRead: json['is_read'] ?? false,
    createdAt: DateTime.parse(json['created_at']),
  );
}

class ProjectMember {
  final String id;
  final String projectId;
  final String userId;
  final String role;
  final DateTime joinedAt;
  final UserProfile? profile;

  ProjectMember({
    required this.id,
    required this.projectId,
    required this.userId,
    required this.role,
    required this.joinedAt,
    this.profile,
  });

  factory ProjectMember.fromJson(Map<String, dynamic> json) => ProjectMember(
    id: json['id'],
    projectId: json['project_id'],
    userId: json['user_id'],
    role: json['role'] ?? 'viewer',
    joinedAt: DateTime.parse(json['joined_at']),
    profile: json['profiles'] != null ? UserProfile.fromJson(json['profiles']) : null,
  );
}
