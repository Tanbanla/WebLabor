import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:web_labor_contract/API/Login_Controller/api_login_controller.dart';
import 'package:web_labor_contract/Screen/User/Home/navigation_drawer.dart';
import 'package:web_labor_contract/Screen/User/LoginScreen/sign_in_screen.dart';
import 'package:web_labor_contract/Screen/User/CreateContract/two_contract.dart';
import 'package:web_labor_contract/Screen/User/CreateContract/apprentice_contract.dart';
import 'package:web_labor_contract/Screen/User/Fill_Review/fill_two.dart';
import 'package:web_labor_contract/Screen/User/Fill_Review/fill_apprentice.dart';
import 'package:web_labor_contract/Screen/User/Approver/approval_two.dart';
import 'package:web_labor_contract/Screen/User/Approver/approval_trial.dart';
import 'package:web_labor_contract/Screen/User/Approver/approval_prepartion.dart';
import 'package:web_labor_contract/Screen/User/Report/report_two.dart';
import 'package:web_labor_contract/Screen/User/Report/report_apprentice.dart';
import 'package:web_labor_contract/Screen/Admin/Master/master_user.dart';
import 'package:web_labor_contract/Screen/Admin/Master/master_pthc.dart';
import 'package:web_labor_contract/Screen/User/Home/home_screen.dart';

// Định nghĩa tên route hằng số để tránh gõ sai
class AppRoutes {
  static const String signIn = '/login';
  static const String home = '/';
  static const String twoContract = '/two';
  static const String apprenticeContract = '/apprentice';
  static const String fillTwo = '/filltwo';
  static const String fillApprentice = '/fillapprentice';
  static const String approvalTwo = '/approvaltwo';
  static const String approvalTrial = '/approvaltrial';
  static const String approvalPreparation = '/approvalpreparation';
  static const String reportTwo = '/reporttwo';
  static const String reportApprentice = '/reportapprentice';
  static const String masterUser = '/masteruser';
  static const String masterPthc = '/masterpthc';
}

GoRouter createRouter(BuildContext context) {
  bool canAccess(AuthState auth, String routePath) {
    final group = auth.user?.chRGroup ?? '';
    final Map<String, List<String>> allowed = {
      AppRoutes.masterUser: ['Admin'],
      AppRoutes.masterPthc: ['Admin'],
      AppRoutes.twoContract: ['Admin', 'Per', 'Chief Per'],
      AppRoutes.apprenticeContract: ['Admin', 'Per', 'Chief Per'],
      AppRoutes.approvalPreparation: ['Admin', 'Per', 'Chief Per'],
      AppRoutes.fillTwo: [
        'Admin',
        'Per',
        'Chief Per',
        'PTHC',
        'Technician',
        'Staff',
        'Operator',
        'Supervisor',
        'Leader',
      ],
      AppRoutes.fillApprentice: [
        'Admin',
        'Per',
        'Chief Per',
        'PTHC',
        'Technician',
        'Staff',
        'Operator',
        'Supervisor',
        'Leader',
      ],
      AppRoutes.approvalTwo: [
        'Admin',
        'Chief Per',
        'Chief Section',
        'Section Manager',
        'General Director',
        'Dept Manager',
        'Director',
      ],
      AppRoutes.approvalTrial: [
        'Admin',
        'Chief Per',
        'Chief Section',
        'Section Manager',
        'General Director',
        'Dept Manager',
        'Director',
      ],
      // thuộc createEvaluation
      // report
      AppRoutes.reportTwo: ['Admin', 'Per', 'Chief Per'],
      AppRoutes.reportApprentice: ['Admin', 'Per', 'Chief Per'],
    };
    if (!allowed.containsKey(routePath)) return true; // home & login
    return allowed[routePath]!.contains(group);
  }

  return GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: Provider.of<AuthState>(context, listen: false),
    redirect: (context, state) {
      final auth = Provider.of<AuthState>(context, listen: false);
      final loggingIn = state.matchedLocation == AppRoutes.signIn;
      if (!auth.isAuthenticated) {
        return loggingIn ? null : AppRoutes.signIn;
      }
      if (loggingIn && auth.isAuthenticated) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.signIn,
        name: 'signIn',
        builder: (context, state) => const SignInScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MenuScreen(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            name: 'home',
            builder: (context, state) => HomeScreen(onNavigate: (_) {}),
          ),
          GoRoute(
            path: AppRoutes.twoContract,
            name: 'twoContract',
            builder: (context, state) => TwoContractScreen(),
            redirect: (context, state) {
              final auth = Provider.of<AuthState>(context, listen: false);
              return canAccess(auth, AppRoutes.twoContract)
                  ? null
                  : AppRoutes.home;
            },
          ),
          GoRoute(
            path: AppRoutes.apprenticeContract,
            name: 'apprenticeContract',
            builder: (context, state) => ApprenticeContractScreen(),
            redirect: (context, state) {
              final auth = Provider.of<AuthState>(context, listen: false);
              return canAccess(auth, AppRoutes.apprenticeContract)
                  ? null
                  : AppRoutes.home;
            },
          ),
          GoRoute(
            path: AppRoutes.fillTwo,
            name: 'fillTwo',
            builder: (context, state) => FillTwoScreen(),
            redirect: (context, state) {
              final auth = Provider.of<AuthState>(context, listen: false);
              return canAccess(auth, AppRoutes.fillTwo) ? null : AppRoutes.home;
            },
          ),
          GoRoute(
            path: AppRoutes.fillApprentice,
            name: 'fillApprentice',
            builder: (context, state) => FillApprenticeScreen(),
            redirect: (context, state) {
              final auth = Provider.of<AuthState>(context, listen: false);
              return canAccess(auth, AppRoutes.fillApprentice)
                  ? null
                  : AppRoutes.home;
            },
          ),
          GoRoute(
            path: AppRoutes.approvalTwo,
            name: 'approvalTwo',
            builder: (context, state) => ApprovalTwoScreen(),
            redirect: (context, state) {
              final auth = Provider.of<AuthState>(context, listen: false);
              return canAccess(auth, AppRoutes.approvalTwo)
                  ? null
                  : AppRoutes.home;
            },
          ),
          GoRoute(
            path: AppRoutes.approvalTrial,
            name: 'approvalTrial',
            builder: (context, state) => ApprovalTrialScreen(),
            redirect: (context, state) {
              final auth = Provider.of<AuthState>(context, listen: false);
              return canAccess(auth, AppRoutes.approvalTrial)
                  ? null
                  : AppRoutes.home;
            },
          ),
          GoRoute(
            path: AppRoutes.approvalPreparation,
            name: 'approvalPreparation',
            builder: (context, state) => ApprovalPrepartionScreen(),
            redirect: (context, state) {
              final auth = Provider.of<AuthState>(context, listen: false);
              return canAccess(auth, AppRoutes.approvalPreparation)
                  ? null
                  : AppRoutes.home;
            },
          ),
          GoRoute(
            path: AppRoutes.reportTwo,
            name: 'reportTwo',
            builder: (context, state) => ReportTwoScreen(),
            redirect: (context, state) {
              final auth = Provider.of<AuthState>(context, listen: false);
              return canAccess(auth, AppRoutes.reportTwo)
                  ? null
                  : AppRoutes.home;
            },
          ),
          GoRoute(
            path: AppRoutes.reportApprentice,
            name: 'reportApprentice',
            builder: (context, state) => ReportApprentice(),
            redirect: (context, state) {
              final auth = Provider.of<AuthState>(context, listen: false);
              return canAccess(auth, AppRoutes.reportApprentice)
                  ? null
                  : AppRoutes.home;
            },
          ),
          GoRoute(
            path: AppRoutes.masterUser,
            name: 'masterUser',
            builder: (context, state) => MasterUser(),
            redirect: (context, state) {
              final auth = Provider.of<AuthState>(context, listen: false);
              return canAccess(auth, AppRoutes.masterUser)
                  ? null
                  : AppRoutes.home;
            },
          ),
          GoRoute(
            path: AppRoutes.masterPthc,
            name: 'masterPthc',
            builder: (context, state) => MasterPTHC(),
            redirect: (context, state) {
              final auth = Provider.of<AuthState>(context, listen: false);
              return canAccess(auth, AppRoutes.masterPthc)
                  ? null
                  : AppRoutes.home;
            },
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) =>
        const Scaffold(body: Center(child: Text('Page not found'))),
  );
}
