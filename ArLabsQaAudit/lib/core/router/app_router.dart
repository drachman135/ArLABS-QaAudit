import 'package:go_router/go_router.dart';
import '../widgets/responsive_layout.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/project/presentation/projects_screen.dart';
import '../../features/project/presentation/project_detail_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/audit/presentation/audit_detail_screen.dart';
import '../../features/audit/domain/audit_model.dart';
import '../../features/bug/presentation/bugs_screen.dart';
import '../../features/bug/presentation/bug_detail_screen.dart';
import '../../features/bug/presentation/bug_form_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return ResponsiveLayout(
          currentPath: state.matchedLocation,
          child: child,
        );
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/projects',
          builder: (context, state) => const ProjectsScreen(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                return ProjectDetailScreen(projectId: id);
              },
              routes: [
                GoRoute(
                  path: 'modules/:moduleId/features/:featureId/functions/:functionId/audit',
                  builder: (context, state) {
                    final projectId = state.pathParameters['id']!;
                    final moduleId = state.pathParameters['moduleId']!;
                    final featureId = state.pathParameters['featureId']!;
                    final functionId = state.pathParameters['functionId']!;

                    final extra = state.extra as Map<String, dynamic>?;
                    final functionName = extra?['functionName'] as String? ?? 'Function';
                    final moduleName = extra?['moduleName'] as String? ?? 'Module';
                    final featureName = extra?['featureName'] as String? ?? 'Feature';
                    final initialAudit = extra?['initialAudit'] as Audit?;

                    return AuditDetailScreen(
                      projectId: projectId,
                      moduleId: moduleId,
                      featureId: featureId,
                      functionId: functionId,
                      functionName: functionName,
                      moduleName: moduleName,
                      featureName: featureName,
                      initialAudit: initialAudit,
                    );
                  },
                ),
                GoRoute(
                  path: 'modules/:moduleId/features/:featureId/functions/:functionId/audit/new-bug',
                  builder: (context, state) {
                    final projectId = state.pathParameters['id']!;
                    final moduleId = state.pathParameters['moduleId']!;
                    final featureId = state.pathParameters['featureId']!;
                    final functionId = state.pathParameters['functionId']!;
                    final extra = state.extra as Map<String, dynamic>?;
                    final auditId = extra?['auditId'] as String?;

                    return BugFormScreen(
                      projectId: projectId,
                      moduleId: moduleId,
                      featureId: featureId,
                      functionId: functionId,
                      auditId: auditId,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/bugs',
          builder: (context, state) => const BugsScreen(),
          routes: [
            GoRoute(
              path: 'new',
              builder: (context, state) {
                final extra = state.extra as Map<String, dynamic>?;
                return BugFormScreen(
                  projectId: extra?['projectId'],
                  moduleId: extra?['moduleId'],
                  featureId: extra?['featureId'],
                  functionId: extra?['functionId'],
                  auditId: extra?['auditId'],
                );
              },
            ),
            GoRoute(
              path: ':bugId',
              builder: (context, state) {
                final bugId = state.pathParameters['bugId']!;
                return BugDetailScreen(bugId: bugId);
              },
              routes: [
                GoRoute(
                  path: 'edit',
                  builder: (context, state) {
                    final bugId = state.pathParameters['bugId']!;
                    final extra = state.extra as Map<String, dynamic>?;
                    final bug = extra?['bug'];
                    return BugFormScreen(
                      bugId: bugId,
                      initialBug: bug,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
  ],
);
