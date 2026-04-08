// lib/config/app_config.dart

class AppConfig {
  // Supabase
  static const supabaseUrl = 'https://liiazqlsslggatfrrvdl.supabase.co';
  static const supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxpaWF6cWxzc2xnZ2F0ZnJydmRsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU2MTc0NzUsImV4cCI6MjA5MTE5MzQ3NX0.983Ed7cgz-2OCBtjmEdfBi4f0CMszPGbVPvRCA-7cog';

  // Google OAuth Client IDs
  static const googleClientIdAndroid =
      '830334671128-beiq4bckhd1tjajsor9t1l23cbd785ac.apps.googleusercontent.com';
  static const googleClientIdIOS =
      '830334671128-mirsktp407olp2fn7t6l7v0gvckg3e5p.apps.googleusercontent.com';
  static const googleClientIdWeb =
      '830334671128-r8rkasagq0iccsut0dqg2jtbl8apquui.apps.googleusercontent.com';

  // App
  static const appName = 'NirmanApp';
  static const appTagline = 'Track your house construction';
  static const superAdminEmail = 'nirmanapphq@gmail.com';
  static const deepLinkScheme = 'io.nirmanapp';
  static const deepLinkHost = 'login-callback';

  // Apple Developer
  static const appleTeamId = '4M469N5493';
  static const bundleId = 'com.nirmanapp.app';

  // Storage buckets
  static const documentsBucket = 'documents';
  static const avatarsBucket = 'avatars';
  static const coversBucket = 'project-covers';

  // Pagination
  static const pageSize = 20;
}

class AppColors {
  static const primary = 0xFF378ADD;
  static const primaryDark = 0xFF185FA5;
  static const success = 0xFF1D9E75;
  static const warning = 0xFFEF9F27;
  static const error = 0xFFE24B4A;
  static const purple = 0xFF7F77DD;
  static const coral = 0xFFD85A30;

  static const phaseColors = {
    'Planning & approvals': 0xFF7F77DD,
    'Foundation': 0xFF1D9E75,
    'Structure & walls': 0xFF378ADD,
    'Roofing': 0xFFEF9F27,
    'Plumbing & electrical': 0xFFD85A30,
    'Finishing & interiors': 0xFFD4537E,
  };
}

class AppStrings {
  static const roleLabels = {
    'super_admin': 'Super Admin',
    'admin': 'Admin',
    'supervisor': 'Supervisor',
    'contractor': 'Contractor',
    'architect': 'Architect',
    'viewer': 'Viewer',
  };

  static const taskStatusLabels = {
    'todo': 'To do',
    'in_progress': 'In progress',
    'done': 'Done',
    'overdue': 'Overdue',
    'cancelled': 'Cancelled',
  };

  static const phaseStatusLabels = {
    'upcoming': 'Upcoming',
    'in_progress': 'In progress',
    'done': 'Done',
    'on_hold': 'On hold',
  };

  static const issueStatusLabels = {
    'open': 'Open',
    'in_progress': 'In progress',
    'resolved': 'Resolved',
    'closed': 'Closed',
  };

  static const expenseCategoryLabels = {
    'materials': 'Materials',
    'labour': 'Labour',
    'equipment': 'Equipment',
    'professional_fees': 'Professional fees',
    'approvals': 'Approvals',
    'misc': 'Miscellaneous',
  };
}
