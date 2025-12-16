import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/friend_models.dart';
import '../../services/friends_service.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/animated_background.dart';
import 'add_friend_dialog.dart';
import 'friend_profile_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Friend>> _friendsFuture;
  late Future<List<FriendRequest>> _requestsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() {
    final friendsService = Provider.of<FriendsService>(context, listen: false);
    setState(() {
      _friendsFuture = friendsService.getFriends();
      _requestsFuture = friendsService.getPendingRequests();
    });
  }

  Future<void> _showAddFriendDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const AddFriendDialog(),
    );

    if (result == true) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      body: Stack(
        children: [
          AnimatedBackground(isDark: themeProvider.isDarkMode),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_rounded),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Friends',
                              style: theme.textTheme.displaySmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Tabs
                      Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          labelColor: theme.colorScheme.onPrimary,
                          unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
                          dividerColor: Colors.transparent,
                          tabs: const [
                            Tab(text: 'Friends'),
                            Tab(text: 'Requests'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildFriendsTab(),
                      _buildRequestsTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddFriendDialog,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Friend'),
      ),
    );
  }

  Widget _buildFriendsTab() {
    return FutureBuilder<List<Friend>>(
      future: _friendsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load friends',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _loadData,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final friends = snapshot.data ?? [];

        if (friends.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline_rounded,
                  size: 64,
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No friends yet',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Add friends to challenge them!',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: friends.length,
          itemBuilder: (context, index) {
            final friend = friends[index];
            return _buildFriendCard(friend, index);
          },
        );
      },
    );
  }

  Widget _buildFriendCard(Friend friend, int index) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FriendProfileScreen(friend: friend),
            ),
          ).then((_) => _loadData());
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                child: Text(
                  friend.user.username.isNotEmpty
                      ? friend.user.username[0].toUpperCase()
                      : '?',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      friend.user.username,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Friends since ${dateFormat.format(friend.friendsSince)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurface.withOpacity(0.3),
              ),
            ],
          ),
        ),
      ),
    ).animate()
      .fadeIn(delay: Duration(milliseconds: 100 * index), duration: 400.ms)
      .slideX(begin: 0.2, end: 0);
  }

  Widget _buildRequestsTab() {
    return FutureBuilder<List<FriendRequest>>(
      future: _requestsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load requests',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _loadData,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No pending requests',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return _buildRequestCard(request, index);
          },
        );
      },
    );
  }

  Widget _buildRequestCard(FriendRequest request, int index) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
              child: Text(
                request.sender.username.isNotEmpty
                    ? request.sender.username[0].toUpperCase()
                    : '?',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.sender.username,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateFormat.format(request.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check_rounded),
                  color: Colors.green,
                  onPressed: () => _acceptRequest(request.id),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  color: Colors.red,
                  onPressed: () => _declineRequest(request.id),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate()
      .fadeIn(delay: Duration(milliseconds: 100 * index), duration: 400.ms)
      .slideX(begin: 0.2, end: 0);
  }

  Future<void> _acceptRequest(String requestId) async {
    try {
      final friendsService = Provider.of<FriendsService>(context, listen: false);
      await friendsService.acceptFriendRequest(requestId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend request accepted!')),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept request: $e')),
        );
      }
    }
  }

  Future<void> _declineRequest(String requestId) async {
    try {
      final friendsService = Provider.of<FriendsService>(context, listen: false);
      await friendsService.declineFriendRequest(requestId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend request declined')),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to decline request: $e')),
        );
      }
    }
  }
}
