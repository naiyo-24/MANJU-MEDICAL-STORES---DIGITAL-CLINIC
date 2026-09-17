import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/lab_models.dart';

import '../screens/splash/splash_screen.dart';
import '../screens/home/dashboard_screen.dart';
import '../screens/auth/role_login_screen.dart';
import '../screens/counter/counter_dashboard.dart';
import '../screens/counter/inventory_screen.dart';
import '../screens/counter/billing_screen.dart';
import '../screens/counter/shop_management_screen.dart';
import '../screens/counter/customers_screen.dart';
import '../screens/counter/history_screen.dart';
import '../screens/counter/accounts_screen.dart';
import '../screens/counter/upload_management_screen.dart';
import '../screens/counter/bill_customization_screen.dart';

import '../screens/lab/lab_dashboard.dart';
import '../screens/lab/lab_dashboard_home.dart';
import '../screens/lab/lab_tests_screen.dart';
import '../screens/lab/lab_templates_screen.dart';
import '../screens/lab/lab_create_template_screen.dart';
import '../screens/lab/lab_packages_screen.dart';
import '../screens/lab/lab_bookings_screen.dart';
import '../screens/lab/lab_sample_tracking_screen.dart';
import '../screens/lab/lab_reports_screen.dart';
import '../screens/lab/lab_send_reports_screen.dart';
import '../screens/lab/lab_history_screen.dart';
import '../screens/lab/lab_accounts_screen.dart';
import '../screens/lab/lab_settings_screen.dart';

import '../screens/crm/crm_dashboard.dart';
import '../screens/crm/crm_dashboard_home.dart';
import '../screens/crm/crm_patients_screen.dart';
import '../screens/crm/crm_appointments_screen.dart';
import '../screens/crm/crm_prescriptions_screen.dart';
import '../screens/crm/crm_doctors_screen.dart';
import '../screens/crm/crm_payment_receipt_screen.dart';
import '../screens/crm/crm_send_to_lab_screen.dart';
import '../screens/crm/crm_orders_screen.dart';
import '../screens/crm/crm_placeholder_screens.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final goRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/role_login',
      builder: (context, state) {
        final Map<String, dynamic> extra = state.extra is Map<String, dynamic> ? state.extra as Map<String, dynamic> : {};
        return RoleLoginScreen(
          roleName: extra['roleName'] is String ? extra['roleName'] as String : 'Counter',
          themeColor: extra['themeColor'] is Color ? extra['themeColor'] as Color : Colors.green,
          nextRoute: extra['nextRoute'] is String ? extra['nextRoute'] as String : '/counter/inventory',
        );
      },
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return CounterDashboard(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/counter/inventory',
              builder: (context, state) => const InventoryScreen(),
              routes: [
                GoRoute(
                  path: 'upload',
                  builder: (context, state) => const UploadManagementScreen(),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/counter/billing',
              builder: (context, state) => const BillingScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/counter/shops',
              builder: (context, state) => const ShopManagementScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/counter/customers',
              builder: (context, state) => const CustomersScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/counter/accounts',
              builder: (context, state) => const AccountsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/counter/history',
              builder: (context, state) => const HistoryScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/counter/settings',
              builder: (context, state) => const BillCustomizationScreen(),
            ),
          ],
        ),
      ],
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return LabDashboard(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(routes: [GoRoute(path: '/lab/dashboard', builder: (context, state) => const LabDashboardHome())]),
        StatefulShellBranch(routes: [GoRoute(path: '/lab/tests', builder: (context, state) => const LabTestsScreen())]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/lab/templates',
            builder: (context, state) => const LabTemplatesScreen(),
            routes: [
              GoRoute(
                path: 'create',
                builder: (context, state) => LabCreateTemplateScreen(existingTemplate: state.extra as LabTemplate?),
              ),
            ],
          ),
        ]),
        StatefulShellBranch(routes: [GoRoute(path: '/lab/packages', builder: (context, state) => const LabPackagesScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/lab/bookings', builder: (context, state) => const LabBookingsScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/lab/tracking', builder: (context, state) => const LabSampleTrackingScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/lab/reports', builder: (context, state) => const LabReportsScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/lab/send_reports', builder: (context, state) => const LabSendReportsScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/lab/history', builder: (context, state) => const LabHistoryScreen())]),
      ],
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return CrmDashboard(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(routes: [GoRoute(path: '/crm/dashboard', builder: (context, state) => const CrmDashboardHome())]),
        StatefulShellBranch(routes: [GoRoute(path: '/crm/patients', builder: (context, state) => const CrmPatientsScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/crm/appointments', builder: (context, state) => const CrmAppointmentsScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/crm/prescriptions', builder: (context, state) => const CrmPrescriptionsScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/crm/doctors', builder: (context, state) => const CrmDoctorsScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/crm/payment_receipt', builder: (context, state) => const CrmPaymentReceiptScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/crm/payment_history', builder: (context, state) => const CrmPaymentHistoryScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/crm/lab_billing', builder: (context, state) => const CrmLabBillingScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/crm/send_to_lab', builder: (context, state) => const CrmSendToLabScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/crm/order_management', builder: (context, state) => const CrmOrdersScreen())]),
      ],
    ),
  ],
);
