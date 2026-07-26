import 'package:flutter/material.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../models/job.dart';
import '../../models/conversation.dart';
import '../../models/profile.dart';
import '../../models/review.dart';

class ChatScreen extends StatefulWidget {
  final AppState appState;
  final String? targetWorkerProfileId;
  final VoidCallback onBack;
  final ValueChanged<String>? onJobCompleteClick;

  const ChatScreen({
    super.key,
    required this.appState,
    this.targetWorkerProfileId,
    required this.onBack,
    this.onJobCompleteClick,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String? _selectedConversationId;
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isRecordingVoice = false;
  int _voiceSec = 0;

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _openConversation(String conversationId) {
    setState(() => _selectedConversationId = conversationId);
  }

  void _closeConversation() {
    setState(() => _selectedConversationId = null);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.appState;
    final conversations = state.conversations;

    if (widget.targetWorkerProfileId != null) {
      return _buildSingleChat(state, widget.targetWorkerProfileId!, conversations);
    }

    if (_selectedConversationId != null) {
      return _buildSingleChatById(state, _selectedConversationId!);
    }

    return _buildConversationList(state, conversations);
  }

  Widget _buildConversationList(AppState state, List<Conversation> conversations) {
    final isEmployer = state.activeProfileType == ProfileType.employer;

    return Column(
      children: [
        _buildHeader('Messages', showBack: false),
        if (conversations.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 48, color: AppColors.slate300),
                  const SizedBox(height: 12),
                  const Text('No conversations yet',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.slate500)),
                  const SizedBox(height: 4),
                  const Text('Chat with workers from job details or the map',
                      style: TextStyle(fontSize: 11, color: AppColors.slate400)),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: conversations.length,
              separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.slate100),
              itemBuilder: (_, i) {
                final conv = conversations[i];
                final partnerId = isEmployer ? conv.workerProfileId : conv.employerProfileId;
                final partnerData = state.getPublicProfile(partnerId);
                final unread = isEmployer ? conv.unreadCountEmployer : conv.unreadCountWorker;
                final lastMsg = conv.lastMessageText ?? 'No messages yet';

                return _ConversationTile(
                  displayName: partnerData?.profile.displayName ?? 'Unknown',
                  photoUrl: partnerData?.profile.profilePhotoUrl,
                  lastMessage: lastMsg,
                  lastTime: conv.lastMessageTime,
                  unreadCount: unread,
                  onTap: () => _openConversation(conv.id),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildHeader(String title, {bool showBack = true}) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.slate200)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (showBack)
            GestureDetector(
              onTap: _closeConversation,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: const Icon(Icons.arrow_back, size: 16, color: AppColors.slate700),
              ),
            ),
          if (showBack) const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.slate800),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleChatById(AppState state, String conversationId) {
    final conv = state.conversations.where((c) => c.id == conversationId).firstOrNull;
    if (conv == null) {
      return _buildConversationList(state, state.conversations);
    }
    return _buildChatView(state, conv);
  }

  Widget _buildSingleChat(AppState state, String targetWorkerProfileId, List<Conversation> conversations) {
    final existingConv = conversations.where(
      (c) => c.workerProfileId == targetWorkerProfileId,
    ).firstOrNull;

    final activeJob = state.jobs.where(
      (j) => j.status == JobStatus.open || j.status == JobStatus.hired,
    ).firstOrNull ?? state.jobs.firstOrNull;

    if (existingConv != null) {
      return _buildChatView(state, existingConv);
    }

    if (activeJob == null) {
      return Column(
        children: [
          _buildHeader('Chat'),
          const Expanded(
            child: Center(
              child: Text('No active job to chat about',
                  style: TextStyle(fontSize: 13, color: AppColors.slate500)),
            ),
          ),
        ],
      );
    }

    final conv = state.getOrCreateConversation(activeJob.id, targetWorkerProfileId);
    return _buildChatView(state, conv);
  }

  Widget _buildChatView(AppState state, Conversation conversation) {
    final convMessages = state.messages
        .where((m) => m.conversationId == conversation.id)
        .toList();
    final isEmployer = state.activeProfileType == ProfileType.employer;
    final partnerId = isEmployer
        ? conversation.workerProfileId
        : conversation.employerProfileId;
    final partnerData = state.getPublicProfile(partnerId);
    final activeJob = state.jobs.where(
      (j) => j.status == JobStatus.open || j.status == JobStatus.hired,
    ).firstOrNull ?? state.jobs.firstOrNull;

    return Column(
      children: [
        _buildChatHeader(state, partnerData, activeJob),
        Expanded(
          child: Column(
            children: [
              if (activeJob != null) _buildJobBanner(activeJob),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: convMessages.length,
                  itemBuilder: (_, i) {
                    final msg = convMessages[i];
                    final isMe = msg.senderProfileId == state.activeProfile?.id;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.78,
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? AppColors.teal600 : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(14),
                            topRight: const Radius.circular(14),
                            bottomLeft: Radius.circular(isMe ? 14 : 4),
                            bottomRight: Radius.circular(isMe ? 4 : 14),
                          ),
                          border: isMe ? null : Border.all(color: AppColors.slate200),
                        ),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg.content,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isMe ? Colors.white : AppColors.slate800,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatTime(msg.sentAt),
                              style: TextStyle(
                                fontSize: 9,
                                color: isMe ? Colors.white70 : AppColors.slate400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        _buildQuickChips(state, conversation, activeJob),
        _buildInputArea(state, conversation),
      ],
    );
  }

  Widget _buildChatHeader(AppState state, ({Profile profile, WorkerDetails? workerDetails, List<Review> reviews})? partnerData, Job? activeJob) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.slate200)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.targetWorkerProfileId != null ? widget.onBack : _closeConversation,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.slate200),
              ),
              child: const Icon(Icons.arrow_back, size: 16, color: AppColors.slate700),
            ),
          ),
          const SizedBox(width: 10),
          if (partnerData?.profile != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(
                partnerData!.profile.profilePhotoUrl,
                width: 36,
                height: 36,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const CircleAvatar(radius: 18, child: Icon(Icons.person)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          partnerData.profile.displayName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.slate800),
                        ),
                      ),
                      if (partnerData.profile.isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.check_circle, size: 14, color: AppColors.teal600),
                      ],
                    ],
                  ),
                  const Text(
                    '● Online in Lahore',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.teal700),
                  ),
                ],
              ),
            ),
          ],
          const Spacer(),
          if (activeJob?.status == JobStatus.hired)
            GestureDetector(
              onTap: () {
                if (activeJob != null) {
                  state.completeJob(activeJob.id);
                  widget.onJobCompleteClick?.call(activeJob.id);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.amber500,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Mark Completed',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildJobBanner(Job activeJob) {
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                const Text('Job: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.teal700)),
                Expanded(
                  child: Text(
                    activeJob.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.slate700),
                  ),
                ),
              ],
            ),
          ),
          Text(
            formatPkr(activeJob.budgetAmount),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.slate800),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChips(AppState state, Conversation conversation, Job? activeJob) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.slate200)),
      ),
      child: Row(
        children: [
          _QuickChip(
            icon: Icons.location_on,
            label: 'Share Pin',
            onTap: activeJob != null
                ? () {
                    state.sendMessage(
                      conversation.id,
                      '📍 Live Location: ${activeJob.pinLocation.address}',
                      contentType: ContentType.location,
                    );
                  }
                : null,
          ),
          const SizedBox(width: 8),
          _QuickChip(
            icon: Icons.attach_money,
            label: 'Quote Offer',
            onTap: activeJob != null
                ? () {
                    state.sendMessage(
                      conversation.id,
                      '💰 Agreed Quote Proposal: ${formatPkr(activeJob.budgetAmount)}',
                      contentType: ContentType.quote,
                    );
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(AppState state, Conversation conversation) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.slate200)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (_isRecordingVoice) return;
              setState(() {
                _isRecordingVoice = true;
                _voiceSec = 0;
              });
              Future.delayed(const Duration(seconds: 3), () {
                if (mounted) {
                  state.sendMessage(conversation.id, '🎤 Voice note (0:03)', contentType: ContentType.voice);
                  setState(() {
                    _isRecordingVoice = false;
                    _voiceSec = 0;
                  });
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _isRecordingVoice ? AppColors.rose500 : AppColors.slate100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.mic, size: 18, color: _isRecordingVoice ? Colors.white : AppColors.slate600),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _msgController,
              decoration: InputDecoration(
                hintText: _isRecordingVoice ? 'Recording voice note... ($_voiceSec s)' : 'Type a message or proposal...',
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.slate200),
                ),
                filled: true,
                fillColor: AppColors.slate50,
              ),
              onSubmitted: (v) {
                if (v.trim().isEmpty) return;
                state.sendMessage(conversation.id, v.trim());
                _msgController.clear();
              },
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              if (_msgController.text.trim().isEmpty) return;
              state.sendMessage(conversation.id, _msgController.text.trim());
              _msgController.clear();
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.teal600,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.teal600.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.send, size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final String displayName;
  final String? photoUrl;
  final String lastMessage;
  final DateTime? lastTime;
  final int unreadCount;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.displayName,
    this.photoUrl,
    required this.lastMessage,
    this.lastTime,
    this.unreadCount = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.network(
                  photoUrl ?? '',
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const CircleAvatar(radius: 22, child: Icon(Icons.person)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayName,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.slate800),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (lastTime != null)
                          Text(
                            formatTime(lastTime!),
                            style: const TextStyle(fontSize: 9, color: AppColors.slate400),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: unreadCount > 0 ? FontWeight.w700 : FontWeight.w500,
                              color: unreadCount > 0 ? AppColors.slate800 : AppColors.slate400,
                            ),
                          ),
                        ),
                        if (unreadCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.teal600,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$unreadCount',
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                          ),
                        ],
                      ],
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

class _QuickChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _QuickChip({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: onTap != null ? AppColors.slate50 : AppColors.slate100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: onTap != null ? AppColors.slate200 : AppColors.slate100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: onTap != null ? AppColors.teal600 : AppColors.slate300),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: onTap != null ? AppColors.slate700 : AppColors.slate300,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
