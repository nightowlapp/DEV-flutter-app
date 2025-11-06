import 'package:flutter/material.dart';

void main() => runApp(const AdminScreen());

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          isDense: true,
        ),
      ),
      home: const AdminPage(),
    );
  }
}

class AdminUser {
  AdminUser({
    required this.id,
    required this.name,
    required this.role,
    required this.createdAt,
    this.active = true,
  });

  int id;
  String name;
  String role;
  DateTime createdAt;
  bool active;
}

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  // --- demo data ---
  final List<AdminUser> _allUsers = List.generate(
    37,
        (i) => AdminUser(
      id: 1000 + i,
      name: i == 0
          ? 'Alice Johnson'
          : i == 1
          ? 'Bob Smith'
          : 'User $i',
      role: i % 5 == 0 ? 'Admin' : (i % 2 == 0 ? 'Editor' : 'Viewer'),
      createdAt: DateTime.now().subtract(Duration(days: 2 * i + 1)),
      active: i % 7 != 0,
    ),
  );

  // filtering + sorting
  final TextEditingController _searchCtrl = TextEditingController();
  int _nextId = 2000;
  int? _sortColumnIndex;
  bool _sortAscending = true;

  // table
  late final _userDataSource = UserDataSource(
    onToggleActive: _toggleActive,
    onEdit: _editUser,
    onDelete: _deleteUser,
  );
  int _rowsPerPage = PaginatedDataTable.defaultRowsPerPage;

  List<AdminUser> _filtered = [];

  @override
  void initState() {
    super.initState();
    _applyFilter();
    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ---- helpers ----
  void _applyFilter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    final list = q.isEmpty
        ? List<AdminUser>.from(_allUsers)
        : _allUsers
        .where((u) =>
    u.name.toLowerCase().contains(q) ||
        u.role.toLowerCase().contains(q) ||
        u.id.toString().contains(q))
        .toList();

    // keep the current sort order
    _sortUsers(list, _sortColumnIndex, _sortAscending);

    setState(() {
      _filtered = list;
      _userDataSource.users = _filtered;
    });
  }

  void _sortUsers(
      List<AdminUser> list,
      int? columnIndex,
      bool ascending,
      ) {
    int comp<T extends Comparable>(T a, T b) =>
        ascending ? a.compareTo(b) : b.compareTo(a);

    switch (columnIndex) {
      case 0: // ID
        list.sort((a, b) => comp(a.id, b.id));
        break;
      case 1: // Name
        list.sort((a, b) => comp(a.name.toLowerCase(), b.name.toLowerCase()));
        break;
      case 2: // Role
        list.sort((a, b) => comp(a.role.toLowerCase(), b.role.toLowerCase()));
        break;
      case 3: // Active
        list.sort((a, b) => comp(a.active ? 1 : 0, b.active ? 1 : 0));
        break;
      case 4: // Created
        list.sort((a, b) => comp(a.createdAt, b.createdAt));
        break;
      default:
      // default: by created desc
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
      _sortUsers(_allUsers, columnIndex, ascending);
      _applyFilter();
    });
  }

  void _toggleActive(AdminUser u, bool value) {
    setState(() {
      u.active = value;
      _applyFilter();
    });
    _snack('User #${u.id} "${u.name}" is now ${u.active ? 'active' : 'inactive'}');
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _addUser() async {
    final result = await showDialog<_EditResult>(
      context: context,
      builder: (_) => EditUserDialog(),
    );

    if (result == null) return;

    setState(() {
      _allUsers.add(AdminUser(
        id: _nextId++,
        name: result.name,
        role: result.role,
        active: result.active,
        createdAt: DateTime.now(),
      ));
      _applyFilter();
    });
    _snack('User "${result.name}" added');
  }

  Future<void> _editUser(AdminUser u) async {
    final result = await showDialog<_EditResult>(
      context: context,
      builder: (_) => EditUserDialog(
        initialName: u.name,
        initialRole: u.role,
        initialActive: u.active,
      ),
    );

    if (result == null) return;

    setState(() {
      u.name = result.name;
      u.role = result.role;
      u.active = result.active;
      _applyFilter();
    });
    _snack('User #${u.id} updated');
  }

  void _deleteUser(AdminUser u) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete user?'),
        content: Text('This will remove "${u.name}" (ID ${u.id}).'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ??
        false;

    if (!ok) return;

    setState(() {
      _allUsers.removeWhere((x) => x.id == u.id);
      _applyFilter();
    });
    _snack('User "${u.name}" deleted');
  }

  int get _activeCount => _allUsers.where((u) => u.active).length;
  int get _adminCount => _allUsers.where((u) => u.role == 'Admin').length;

  // ---- UI ----
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        centerTitle: true,
      ),
      drawer: const _AdminDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addUser,
        icon: const Icon(Icons.person_add),
        label: const Text('Add user'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // KPIs
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _StatCard(
                      title: 'Total Users',
                      value: _allUsers.length.toString(),
                      color: Colors.indigo,
                      icon: Icons.people,
                    ),
                    _StatCard(
                      title: 'Active',
                      value: _activeCount.toString(),
                      color: Colors.green,
                      icon: Icons.verified_user,
                    ),
                    _StatCard(
                      title: 'Admins',
                      value: _adminCount.toString(),
                      color: Colors.orange,
                      icon: Icons.admin_panel_settings,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Search + actions row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Search by id, name or role…',
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (!isWide)
                      IconButton.outlined(
                        tooltip: 'Clear',
                        onPressed: () {
                          _searchCtrl.clear();
                          _applyFilter();
                        },
                        icon: const Icon(Icons.close),
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: () {
                          _searchCtrl.clear();
                          _applyFilter();
                        },
                        icon: const Icon(Icons.clear),
                        label: const Text('Clear'),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                // Data table
                Card(
                  elevation: 0,
                  clipBehavior: Clip.antiAlias,
                  child: PaginatedDataTable(
                    header: const Text('Users'),
                    columns: [
                      DataColumn(
                        label: const Text('ID'),
                        numeric: true,
                        onSort: (i, asc) => _onSort(i, asc),
                      ),
                      DataColumn(
                        label: const Text('Name'),
                        onSort: (i, asc) => _onSort(i, asc),
                      ),
                      DataColumn(
                        label: const Text('Role'),
                        onSort: (i, asc) => _onSort(i, asc),
                      ),
                      DataColumn(
                        label: const Text('Active'),
                        onSort: (i, asc) => _onSort(i, asc),
                      ),
                      DataColumn(
                        label: const Text('Created'),
                        onSort: (i, asc) => _onSort(i, asc),
                      ),
                      const DataColumn(label: Text('Actions')),
                    ],
                    sortColumnIndex: _sortColumnIndex,
                    sortAscending: _sortAscending,
                    source: _userDataSource,
                    rowsPerPage: _rowsPerPage.clamp(5, 20),
                    availableRowsPerPage: const [5, 10, 15, 20],
                    onRowsPerPageChanged: (v) {
                      if (v == null) return;
                      setState(() => _rowsPerPage = v);
                    },
                    showCheckboxColumn: false,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AdminDrawer extends StatelessWidget {
  const _AdminDrawer();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            DrawerHeader(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: color.primary.withOpacity(.1),
                    child: Icon(Icons.admin_panel_settings, color: color.primary),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Admin',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Users'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () => Navigator.pop(context),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign out'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String title;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cardColor = color.withOpacity(.08);
    return Container(
      width: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: Colors.black54)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class UserDataSource extends DataTableSource {
  UserDataSource({
    required this.onToggleActive,
    required this.onEdit,
    required this.onDelete,
  });

  late List<AdminUser> _users = [];
  set users(List<AdminUser> value) {
    _users = value;
    notifyListeners();
  }

  List<AdminUser> get users => _users;

  final void Function(AdminUser user, bool value) onToggleActive;
  final Future<void> Function(AdminUser user) onEdit;
  final void Function(AdminUser user) onDelete;

  String _fmtDate(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
    // Keep it package-free; add intl if you want fancier formats.
  }

  @override
  DataRow? getRow(int index) {
    if (index >= users.length) return null;
    final u = users[index];

    return DataRow.byIndex(
      index: index,
      cells: [
        DataCell(Text(u.id.toString())),
        DataCell(Text(u.name)),
        DataCell(Text(u.role)),
        DataCell(Switch(
          value: u.active,
          onChanged: (v) => onToggleActive(u, v),
        )),
        DataCell(Text(_fmtDate(u.createdAt))),
        DataCell(
          Wrap(
            spacing: 8,
            children: [
              IconButton(
                tooltip: 'Edit',
                onPressed: () => onEdit(u),
                icon: const Icon(Icons.edit, size: 20),
              ),
              IconButton(
                tooltip: 'Delete',
                onPressed: () => onDelete(u),
                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => users.length;

  @override
  int get selectedRowCount => 0;
}

class _EditResult {
  _EditResult({required this.name, required this.role, required this.active});
  final String name;
  final String role;
  final bool active;
}

class EditUserDialog extends StatefulWidget {
  const EditUserDialog({
    super.key,
    this.initialName,
    this.initialRole,
    this.initialActive,
  });

  final String? initialName;
  final String? initialRole;
  final bool? initialActive;

  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  late final TextEditingController _nameCtrl =
  TextEditingController(text: widget.initialName ?? '');
  late final TextEditingController _roleCtrl =
  TextEditingController(text: widget.initialRole ?? 'Viewer');
  final _formKey = GlobalKey<FormState>();
  bool _active = true;

  @override
  void initState() {
    super.initState();
    _active = widget.initialActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _roleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialName != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit user' : 'Add user'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
                autofocus: true,
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _roleCtrl,
                decoration: const InputDecoration(labelText: 'Role'),
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                value: _active,
                onChanged: (v) => setState(() => _active = v),
                title: const Text('Active'),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              _EditResult(
                name: _nameCtrl.text.trim(),
                role: _roleCtrl.text.trim(),
                active: _active,
              ),
            );
          },
          child: Text(isEdit ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}
