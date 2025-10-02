import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/role_selection_page.dart';
import 'screens/signin_page.dart';
import 'screens/home_page.dart';
import 'screens/report_issue_page.dart';
import 'screens/complaint_detail_screen.dart';
import 'screens/worker_login_page.dart';
import 'screens/worker_dashboard_page.dart';
import 'screens/pending_tasks_page.dart';
import 'screens/completed_tasks_page.dart';
import 'services/worker_task_service.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => WorkerTaskService(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Civic Sense',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      initialRoute: '/role-selection',
      routes: {
        '/role-selection': (context) => const RoleSelectionPage(),
        '/signin': (context) => const SignInPage(),
        '/home': (context) => const HomePage(),
        '/report-issue': (context) => const ReportIssuePage(),
        '/worker-login': (context) => const WorkerLoginPage(),
        '/worker-dashboard': (context) => const WorkerDashboardPage(),
        '/pending-tasks': (context) => const PendingTasksPage(),
        '/completed-tasks': (context) => const CompletedTasksPage(),
      },
    );
  }
}

