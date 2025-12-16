import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'dart:io';

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  String? _selectedChatId;
  String? _selectedChatName;
  String? _selectedGroupId;
  String? _selectedGroupName;

  void _handleChatSelected(String id, String name) {
    setState(() {
      _selectedChatId = id;
      _selectedChatName = name;
      _selectedGroupId = null;
      _selectedGroupName = null;
    });
  }

  void _handleGroupSelected(String id, String name) {
    setState(() {
      _selectedGroupId = id;
      _selectedGroupName = name;
      _selectedChatId = null;
      _selectedChatName = null;
    });
  }

  void _handleBack() {
    setState(() {
      _selectedChatId = null;
      _selectedChatName = null;
      _selectedGroupId = null;
      _selectedGroupName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedChatId != null && _selectedChatName != null) {
      return ChatScreen(
        receiverId: _selectedChatId!,
        receiverName: _selectedChatName!,
        onBack: _handleBack,
      );
    }

    if (_selectedGroupId != null && _selectedGroupName != null) {
      return GroupChatScreen(
        groupId: _selectedGroupId!,
        groupName: _selectedGroupName!,
        onBack: _handleBack,
      );
    }

    return DefaultTabController(
      length: 2, // Chats, Groups
      child: SizedBox(
        height: double.infinity, // Force full height
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFEF5350),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: const Text(
                  'Messages',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Tabs
              const TabBar(
                labelColor: Color(0xFFEF5350),
                unselectedLabelColor: Colors.grey,
                indicatorColor: Color(0xFFEF5350),
                tabs: [
                  Tab(text: 'Chats'),
                  Tab(text: 'Groups'),
                ],
              ),

              // Content with FAB
              Expanded(
                child: Stack(
                  children: [
                    TabBarView(
                      children: [
                        _RecentChatsList(onChatSelected: _handleChatSelected),
                        _GroupsList(onGroupSelected: _handleGroupSelected),
                      ],
                    ),
                    Positioned(
                      right: 16,
                      bottom: 16,
                      child: FloatingActionButton(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ContactListScreen(),
                            ),
                          );

                          if (result != null &&
                              result is Map &&
                              result.containsKey('id') &&
                              result.containsKey('name')) {
                            _handleChatSelected(result['id'], result['name']);
                          }
                        },
                        backgroundColor: const Color(0xFFEF5350),
                        child: const Icon(
                          Icons.add_comment_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentChatsList extends StatelessWidget {
  final Function(String, String) onChatSelected;

  const _RecentChatsList({required this.onChatSelected});

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser!.id;

    // Stream 1: Recent messages to build the list of conversations
    final recentMessagesStream = Supabase.instance.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(50);

    // Stream 2: Unread messages count for this user
    final unreadMessagesStream = Supabase.instance.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .map(
          (messages) => messages
              .where(
                (m) =>
                    m['receiver_id'] == currentUserId && m['status'] != 'read',
              )
              .toList(),
        );

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: recentMessagesStream,
      builder: (context, recentSnapshot) {
        if (!recentSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final messages = recentSnapshot.data!;
        final Map<String, Map<String, dynamic>> lastMessages = {};

        for (var msg in messages) {
          final sender = msg['sender_id'];
          final receiver = msg['receiver_id'];

          if (sender != currentUserId && receiver != currentUserId) continue;

          final partnerId = sender == currentUserId ? receiver : sender;
          if (!lastMessages.containsKey(partnerId)) {
            lastMessages[partnerId] = msg;
          }
        }

        if (lastMessages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  "No recent chats",
                  style: TextStyle(color: Colors.grey[500], fontSize: 16),
                ),
              ],
            ),
          );
        }

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: unreadMessagesStream,
          builder: (context, unreadSnapshot) {
            // Calculate unread counts per sender
            final unreadCounts = <String, int>{};
            if (unreadSnapshot.hasData) {
              for (var msg in unreadSnapshot.data!) {
                final sender = msg['sender_id'] as String;
                unreadCounts[sender] = (unreadCounts[sender] ?? 0) + 1;
              }
            }

            return FutureBuilder(
              future: Supabase.instance.client
                  .from('profiles')
                  .select()
                  .filter('id', 'in', lastMessages.keys.toList()),
              builder: (context, profileSnapshot) {
                if (!profileSnapshot.hasData) return const SizedBox.shrink();

                final profiles = List<Map<String, dynamic>>.from(
                  profileSnapshot.data as List,
                );
                final profileMap = {for (var p in profiles) p['id']: p};

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: lastMessages.length,
                  itemBuilder: (context, index) {
                    final partnerId = lastMessages.keys.elementAt(index);
                    final msg = lastMessages[partnerId]!;
                    final profile = profileMap[partnerId];

                    if (profile == null) return const SizedBox.shrink();

                    final name = profile['full_name'] ?? 'Unknown User';
                    final avatarUrl = profile['avatar_url'];
                    final time = DateTime.parse(msg['created_at']).toLocal();
                    final unreadCount = unreadCounts[partnerId] ?? 0;

                    return ListTile(
                      leading: CircleAvatar(
                        radius: 25,
                        backgroundImage: avatarUrl != null
                            ? NetworkImage(avatarUrl)
                            : null,
                        child: avatarUrl == null
                            ? Text(name[0].toUpperCase())
                            : null,
                      ),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            timeago.format(time, locale: 'en_short'),
                            style: TextStyle(
                              color: unreadCount > 0
                                  ? const Color(0xFF25D366)
                                  : Colors.grey[600],
                              fontSize: 12,
                              fontWeight: unreadCount > 0
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      subtitle: Row(
                        children: [
                          Expanded(
                            child: Text(
                              msg['content'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: unreadCount > 0
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: unreadCount > 0
                                    ? Colors.black87
                                    : Colors.grey[600],
                              ),
                            ),
                          ),
                          if (unreadCount > 0)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFF25D366),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      onTap: () => onChatSelected(partnerId, name),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _GroupsList extends StatelessWidget {
  final Function(String, String) onGroupSelected;

  const _GroupsList({required this.onGroupSelected});

  @override
  Widget build(BuildContext context) {
    // Current user Groups
    final myGroupsFuture = Supabase.instance.client
        .from('group_members')
        .select('group_id, groups(id, name, description)')
        .eq('user_id', Supabase.instance.client.auth.currentUser!.id);

    return FutureBuilder(
      future: myGroupsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                const Text(
                  "Groups not configured yet",
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
                Text(
                  "${snapshot.error}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final data = snapshot.data as List<dynamic>;
        if (data.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.group_outlined, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  "You haven't joined any groups",
                  style: TextStyle(color: Colors.grey[500], fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: data.length,
          itemBuilder: (context, index) {
            final item = data[index];
            final group = item['groups'];
            final groupName = group['name'] as String;
            final groupDesc = group['description'] as String?;

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.red[100],
                child: const Icon(Icons.groups, color: Color(0xFFEF5350)),
              ),
              title: Text(
                groupName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(groupDesc ?? 'No description'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => onGroupSelected(group['id'], groupName),
            );
          },
        );
      },
    );
  }
}

class ContactListScreen extends StatelessWidget {
  const ContactListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser!.id;
    final usersStream = Supabase.instance.client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .order('full_name');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Contact'),
        backgroundColor: const Color(0xFFEF5350),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: usersStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!;
          final otherUsers = users
              .where((u) => u['id'] != currentUserId)
              .toList();

          if (otherUsers.isEmpty) {
            return const Center(child: Text('No other users found.'));
          }

          return ListView.separated(
            itemCount: otherUsers.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final user = otherUsers[index];
              final name = user['full_name'] ?? 'Unknown';
              final role = user['role'] ?? 'User';
              final avatarUrl = user['avatar_url'];

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  radius: 25,
                  backgroundImage: avatarUrl != null
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: avatarUrl == null ? Text(name[0].toUpperCase()) : null,
                ),
                title: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(role),
                onTap: () {
                  // Return data to ChatView
                  Navigator.pop(context, {'id': user['id'], 'name': name});
                },
              );
            },
          );
        },
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final VoidCallback? onBack;

  const ChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
    this.onBack,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _currentUserId = Supabase.instance.client.auth.currentUser!.id;
  final FocusNode _focusNode = FocusNode();
  late String _conversationId;
  bool _showEmoji = false;
  bool _isUploading = false;

  // Optimistic UI: Stores messages that are sending but not yet confirmed by stream
  final List<Map<String, dynamic>> _optimisticMessages = [];

  @override
  void initState() {
    super.initState();
    final ids = [_currentUserId, widget.receiverId]..sort();
    _conversationId = "${ids[0]}_${ids[1]}";

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() {
          _showEmoji = false;
        });
      }
    });

    // Mark unread messages as READ when entering screen
    _markMessagesAsRead();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // Mark messages from the OTHER person as read
  Future<void> _markMessagesAsRead() async {
    try {
      await Supabase.instance.client
          .from('messages')
          .update({'status': 'read'})
          .eq('conversation_id', _conversationId)
          .eq('receiver_id', _currentUserId)
          .neq('status', 'read');
    } catch (_) {
      // Ignore errors, not critical
    }
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    // 1. Optimistic Update (Show instantly)
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    final optimisticMsg = {
      'id': tempId,
      'sender_id': _currentUserId,
      'receiver_id': widget.receiverId,
      'content': text,
      'created_at': DateTime.now().toIso8601String(),
      'status': 'sending', // Local status
      'is_optimistic': true,
    };

    setState(() {
      _optimisticMessages.add(optimisticMsg);
    });

    try {
      // 2. Send to Server
      await Supabase.instance.client.from('messages').insert({
        'sender_id': _currentUserId,
        'receiver_id': widget.receiverId,
        'content': text,
        'conversation_id': _conversationId,
        'status': 'sent',
      });

      // On success, the Stream will pick up the real message.
      // We remove the optimistic one when we see the real one (or just clear list after short delay if simple)
      // Correct way: The stream update will trigger a rebuild. We can remove our optimistic one if we want,
      // but simpler is to just keep it until we confirm.
      // For this implementation, we will clear optimistic msg once we know it's sent,
      // effectively letting the Stream take over.
      setState(() {
        _optimisticMessages.removeWhere((m) => m['id'] == tempId);
      });
    } catch (e) {
      setState(() {
        // Mark as failed in optimistic list? Or just removing for now.
        _optimisticMessages.removeWhere((m) => m['id'] == tempId);
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sending: $e')));
      }
    }
  }

  Widget _buildStatusIcon(String status, bool isMe) {
    if (!isMe) return const SizedBox(width: 0);

    IconData icon;
    Color color;

    switch (status) {
      case 'sending':
        icon = Icons.access_time;
        color = Colors.grey;
        break;
      case 'sent':
        icon = Icons.check;
        color = Colors.grey;
        break;
      case 'delivered':
        icon = Icons.done_all;
        color = Colors.grey;
        break;
      case 'read':
        icon = Icons.done_all;
        color = Colors.blue;
        break;
      default:
        icon = Icons.check;
        color = Colors.grey;
    }

    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 2),
      child: Icon(icon, size: 14, color: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stream = Supabase.instance.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', _conversationId)
        .order('created_at', ascending: true);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receiverName),
        backgroundColor: const Color(0xFFEF5350),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: stream,
              builder: (context, snapshot) {
                // Combine Stream data with Optimistic data
                List<Map<String, dynamic>> messages = [];

                if (snapshot.hasData) {
                  messages.addAll(snapshot.data!);
                  // If we found new messages from the other person that aren't read, mark them read!
                  // We do this responsibly to avoid loops.
                  final unreadExists = messages.any(
                    (m) =>
                        m['receiver_id'] == _currentUserId &&
                        m['status'] != 'read',
                  );
                  if (unreadExists) {
                    // Trigger mark read in background
                    Future.delayed(Duration.zero, _markMessagesAsRead);
                  }
                }

                // Append optimistic messages that aren't yet in the stream (deduplication simplified)
                // We'll just append all optimistic ones at the end for now.
                messages.addAll(_optimisticMessages);

                if (messages.isEmpty && !snapshot.hasError) {
                  return const Center(child: Text('Say Hi! 👋'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['sender_id'] == _currentUserId;
                    final time = DateTime.parse(msg['created_at']).toLocal();
                    final status = msg['status'] ?? 'sent';

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 12,
                          top: 10,
                          bottom: 10,
                        ),
                        constraints: const BoxConstraints(maxWidth: 300),
                        decoration: BoxDecoration(
                          color: isMe
                              ? const Color(0xFFEF5350)
                              : Colors.grey[200],
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isMe ? 16 : 0),
                            bottomRight: Radius.circular(isMe ? 0 : 16),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _buildMessageContent(msg['content'], isMe),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  timeago.format(time, locale: 'en_short'),
                                  style: TextStyle(
                                    color: isMe
                                        ? Colors.white70
                                        : Colors.grey[600],
                                    fontSize: 10,
                                  ),
                                ),
                                if (isMe) _buildStatusIcon(status, isMe),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (_isUploading)
            const LinearProgressIndicator(
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEF5350)),
            ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _showEmoji = !_showEmoji;
                          if (_showEmoji) {
                            _focusNode.unfocus();
                          } else {
                            _focusNode.requestFocus();
                          }
                        });
                      },
                      icon: Icon(
                        _showEmoji
                            ? Icons.keyboard
                            : Icons.emoji_emotions_outlined,
                        color: Colors.grey,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.attach_file, color: Colors.grey),
                      onPressed: _pickAndUploadFile,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        focusNode: _focusNode,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: const Color(0xFFEF5350),
                      child: IconButton(
                        icon: const Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
                if (_showEmoji)
                  SizedBox(
                    height: 250,
                    child: EmojiPicker(
                      onEmojiSelected: (category, emoji) {
                        _messageController.text += emoji.emoji;
                      },
                      config: const Config(
                        categoryViewConfig: CategoryViewConfig(
                          indicatorColor: Color(0xFFEF5350),
                          iconColorSelected: Color(0xFFEF5350),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;

        // Check size (25MB limit)
        // 25MB = 25 * 1024 * 1024 bytes
        if (file.size > 25 * 1024 * 1024) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File size exceeds 25MB limit')),
          );
          return;
        }

        setState(() {
          _isUploading = true;
        });

        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
        // Remove spaces and special chars potentially
        final safeFileName = fileName.replaceAll(
          RegExp(r'[^a-zA-Z0-9._-]'),
          '',
        );

        // Upload
        final storage = Supabase.instance.client.storage.from(
          'chat_attachments',
        );

        if (foundation.kIsWeb) {
          if (file.bytes != null) {
            await storage.uploadBinary(safeFileName, file.bytes!);
          } else {
            throw 'No file data found';
          }
        } else {
          if (file.path != null) {
            final ioFile = File(file.path!);
            await storage.upload(safeFileName, ioFile);
          } else if (file.bytes != null) {
            // Fallback if path is null
            await storage.uploadBinary(safeFileName, file.bytes!);
          }
        }

        final publicUrl = storage.getPublicUrl(safeFileName);

        // Send as message
        _messageController.text = publicUrl;
        _sendMessage();
      }
    } catch (e) {
      if (mounted) {
        String msg = 'Error uploading file: $e';
        if (e.toString().contains('403') ||
            e.toString().contains('row-level security')) {
          msg =
              "Permission denied. Please ensure 'chat_attachments' bucket exists and has public RLS policies.";
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Widget _buildMessageContent(String content, bool isMe) {
    if (content.startsWith('http')) {
      final lower = content.toLowerCase();
      final isImage =
          lower.endsWith('.jpg') ||
          lower.endsWith('.jpeg') ||
          lower.endsWith('.png') ||
          lower.endsWith('.gif') ||
          lower.endsWith('.webp');

      if (isImage) {
        return GestureDetector(
          onTap: () => launchUrl(Uri.parse(content)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              content,
              width: 200,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Text('⚠ Error loading image');
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return SizedBox(
                  width: 200,
                  height: 150,
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                          : null,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      } else {
        // Generic File
        return InkWell(
          onTap: () => launchUrl(Uri.parse(content)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.insert_drive_file,
                color: isMe ? Colors.white : Colors.black54,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'View Attachment',
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    }

    return Text(
      content,
      style: TextStyle(
        color: isMe ? Colors.white : Colors.black87,
        fontSize: 16,
      ),
    );
  }
}

class GroupChatScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  final VoidCallback? onBack;

  const GroupChatScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    this.onBack,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final _messageController = TextEditingController();
  final _currentUserId = Supabase.instance.client.auth.currentUser!.id;

  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
    _messageController.clear();

    try {
      await Supabase.instance.client.from('group_messages').insert({
        'group_id': widget.groupId,
        'sender_id': _currentUserId,
        'content': message,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sending message: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine stream for group messages
    final messageStream = Supabase.instance.client
        .from('group_messages')
        .stream(primaryKey: ['id'])
        .eq('group_id', widget.groupId)
        .order('created_at', ascending: true);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName),
        backgroundColor: const Color(0xFFEF5350),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // TODO: Show group info / members
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: messageStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!;
                if (messages.isEmpty) {
                  return const Center(
                    child: Text('No messages yet. Start the conversation!'),
                  );
                }

                // We need to fetch sender profiles to show names
                // Optimally we'd join or pre-fetch, but for now we'll fetch sender name on the fly or just show ID/placeholder
                // A better approach is fetching all group members upfront.

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['sender_id'] == _currentUserId;
                    final time = DateTime.parse(msg['created_at']).toLocal();

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (!isMe) ...[
                            FutureBuilder(
                              future: Supabase.instance.client
                                  .from('profiles')
                                  .select('avatar_url, full_name')
                                  .eq('id', msg['sender_id'])
                                  .single(),
                              builder: (context, snap) {
                                if (snap.hasData) {
                                  final data = snap.data as Map;
                                  final avatarUrl = data['avatar_url'];
                                  final name = data['full_name'] ?? '?';
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      right: 8,
                                      bottom: 4,
                                    ),
                                    child: CircleAvatar(
                                      radius: 16,
                                      backgroundImage: avatarUrl != null
                                          ? NetworkImage(avatarUrl)
                                          : null,
                                      child: avatarUrl == null
                                          ? Text(
                                              name[0].toUpperCase(),
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            )
                                          : null,
                                    ),
                                  );
                                }
                                return const SizedBox(width: 40);
                              },
                            ),
                          ],
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            constraints: const BoxConstraints(maxWidth: 300),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? const Color(0xFFEF5350)
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: Radius.circular(isMe ? 16 : 0),
                                bottomRight: Radius.circular(isMe ? 0 : 16),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isMe) ...[
                                  FutureBuilder(
                                    future: Supabase.instance.client
                                        .from('profiles')
                                        .select('full_name')
                                        .eq('id', msg['sender_id'])
                                        .single(),
                                    builder: (context, snap) {
                                      if (snap.hasData) {
                                        final name =
                                            (snap.data as Map)['full_name'];
                                        return Text(
                                          name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: Colors.black54,
                                          ),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                  const SizedBox(height: 4),
                                ],
                                Text(
                                  msg['content'],
                                  style: TextStyle(
                                    color: isMe ? Colors.white : Colors.black87,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Text(
                                    timeago.format(time, locale: 'en_short'),
                                    style: TextStyle(
                                      color: isMe
                                          ? Colors.white70
                                          : Colors.grey[600],
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Input Area
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFFEF5350),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
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
