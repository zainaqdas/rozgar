import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/providers.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../models/job.dart';
import '../../models/conversation.dart';
import '../../models/profile.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String? targetWorkerProfileId;
  final VoidCallback onBack;
  final ValueChanged<String>? onJobCompleteClick;

  const ChatScreen({
    super.key,
    this.targetWorkerProfileId,
    required this.onBack,
    this.onJobCompleteClick,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  String? _selectedConversationId;
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();
  final bool _isRecordingVoice = false;
  final int _voiceSec = 0;

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _openConversation(String conversationId) {
    setState(() => _selectedConversationId = conversationId);
  }

  void _closeConversation() {
    setState(() => _selectedConversationId = null);
  }

  @override
  Widget build(BuildContext context) {
    final chatNotifier = ref.watch(chatProvider);
    final conversations = chatNotifier.conversations;

    if (widget.targetWorkerProfileId != null) {
      return _buildSingleChat(widget.targetWorkerProfileId!, conversations);
    }

    if (_selectedConversationId != null) {
      return _buildSingleChatById(_selectedConversationId!);
    }

    return _buildConversationList(conversations);
  }

  Widget _buildConversationList(List<Conversation> conversations) {
    return Column(
      children: [
        _buildHeader('Messages', showBack: false),
        Expanded(
          child: conversations.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 48, color: AppColors.slate300),
                      SizedBox(height: 12),
                      Text('No conversations yet',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.slate500)),
                      SizedBox(height: 4),
                      Text('Conversations start when you hire a worker.',
                          style: TextStyle(fontSize: 12, color: AppColors.slate400)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: conversations.length,
                  itemBuilder: (context, index) {
                    final conv = conversations[index];
                    final profile = ref.read(profileProvider);
                    final isEmployer = profile.activeProfileType == ProfileType.employer;
                    final partnerId = isEmployer ? conv.workerProfileId : conv.employerProfileId;
                    final partnerData = ref.read(workerProvider).getPublicProfile(
                      partnerId, profile.workerProfile, profile.workerDetails);
                    final displayName = partnerData?.profile.displayName ?? 'User';

                    return GestureDetector(
                      onTap: () => _openConversation(conv.id),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.slate200),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.teal50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.teal200),
                              ),
                              child: Center(
                                child: Text(
                                  displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.teal700),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(displayName,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.slate800)),
                                  const SizedBox(height: 2),
                                  Text(
                                    conv.lastMessageText ?? 'No messages yet',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 11, color: AppColors.slate500),
                                  ),
                                ],
                              ),
                            ),
                            if (conv.lastMessageTime != null)
                              Text(timeAgo(conv.lastMessageTime!),
                                  style: const TextStyle(fontSize: 9, color: AppColors.slate400)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildHeader(String title, {bool showBack = true}) {
    return Container(
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

  Widget _buildSingleChatById(String conversationId) {
    final chatNotifier = ref.watch(chatProvider);
    final conv = chatNotifier.conversations.where((c) => c.id == conversationId).firstOrNull;
    if (conv == null) {
      return _buildConversationList(chatNotifier.conversations);
    }
    return _buildChatView(conv);
  }

  Widget _buildSingleChat(String targetWorkerProfileId, List<Conversation> conversations) {
    final existingConv = conversations.where(
      (c) => c.workerProfileId == targetWorkerProfileId,
    ).firstOrNull;

    final jobs = ref.watch(jobProvider).jobs;
    final activeJob = jobs.where(
      (j) => j.status == JobStatus.open || j.status == JobStatus.hired,
    ).firstOrNull ?? jobs.firstOrNull;

    if (existingConv != null) {
      return _buildChatView(existingConv);
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

    final profile = ref.read(profileProvider);
    final employerId = profile.employerProfile?.id ?? '';
    final conv = ref.read(chatProvider.notifier).getOrCreateConversation(
      activeJob.id, targetWorkerProfileId, employerId);
    return _buildChatView(conv);
  }

  Widget _buildChatView(Conversation conversation) {
    final chatNotifier = ref.watch(chatProvider);
    final profile = ref.watch(profileProvider);
    final jobs = ref.watch(jobProvider).jobs;
    final convMessages = chatNotifier.messages
        .where((m) => m.conversationId == conversation.id)
        .toList();
    final isEmployer = profile.activeProfileType == ProfileType.employer;
    final partnerId = isEmployer
        ? conversation.workerProfileId
        : conversation.employerProfileId;
    final partnerData = ref.read(workerProvider).getPublicProfile(
      partnerId, profile.workerProfile, profile.workerDetails);
    final activeJob = jobs.where(
      (j) => j.status == JobStatus.open || j.status == JobStatus.hired,
    ).firstOrNull ?? jobs.firstOrNull;

    return Column(
      children: [
        _buildChatHeader(partnerData, activeJob),
        Expanded(
          child: Column(
            children: [
              if (activeJob != null) _buildJobBanner(activeJob),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: convMessages.length,
                  itemBuilder: (context, index) {
                    final msg = convMessages[index];
                    final isMine = msg.senderProfileId == profile.activeProfile?.id;
                    return _buildMessageBubble(msg, isMine);
                  },
                ),
              ),
            ],
          ),
        ),
        _buildQuickChips(conversation, activeJob),
        _buildMessageInput(conversation),
      ],
    );
  }

  Widget _buildMessageBubble(Message msg, bool isMine) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: const BoxConstraints(maxWidth: 260),
        decoration: BoxDecoration(
          color: isMine ? AppColors.teal600 : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isMine ? 14 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 14),
          ),
          border: isMine ? null : Border.all(color: AppColors.slate200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (msg.contentType == ContentType.image && msg.mediaUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(msg.mediaUrl!, width: 200, fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Icon(Icons.broken_image, size: 40)),
              )
            else if (msg.contentType == ContentType.location)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on, size: 14, color: isMine ? Colors.white : AppColors.teal600),
                  const SizedBox(width: 4),
                  Flexible(child: Text(msg.content,
                      style: TextStyle(fontSize: 12, color: isMine ? Colors.white : AppColors.slate700))),
                ],
              )
            else
              Text(msg.content,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                      color: isMine ? Colors.white : AppColors.slate700, height: 1.3)),
            const SizedBox(height: 3),
            Text(timeAgo(msg.sentAt),
                style: TextStyle(fontSize: 8, color: isMine ? Colors.white60 : AppColors.slate400)),
          ],
        ),
      ),
    );
  }

  Widget _buildChatHeader(
      ({Profile profile, WorkerDetails? workerDetails})? partnerData, Job? activeJob) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.slate200)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _closeConversation,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.slate50,
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
                  ref.read(jobProvider.notifier).completeJob(activeJob.id);
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
                const Icon(Icons.work_outline, size: 16, color: AppColors.teal600),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(activeJob.title,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.slate800)),
                      Text(activeJob.pinLocation.address,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 9, color: AppColors.slate500)),
                    ],
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

  Widget _buildQuickChips(Conversation conversation, Job? activeJob) {
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
                    final senderId = ref.read(profileProvider).activeProfile?.id ?? '';
                    ref.read(chatProvider.notifier).sendMessage(
                      conversation.id,
                      '📍 Live Location: ${activeJob.pinLocation.address}',
                      senderProfileId: senderId,
                      contentType: ContentType.location,
                    );
                    _scrollToBottom();
                  }
                : null,
          ),
          const SizedBox(width: 8),
          _QuickChip(
            icon: Icons.attach_money,
            label: 'Quote Offer',
            onTap: activeJob != null
                ? () {
                    final senderId = ref.read(profileProvider).activeProfile?.id ?? '';
                    ref.read(chatProvider.notifier).sendMessage(
                      conversation.id,
                      '💰 Quote: ${formatPkr(activeJob.budgetAmount)} (${activeJob.budgetType.name})',
                      senderProfileId: senderId,
                      contentType: ContentType.quote,
                    );
                    _scrollToBottom();
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput(Conversation conversation) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.slate200)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _pickAndSendImage(conversation.id),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.slate100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.camera_alt_outlined, size: 18, color: AppColors.slate600),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _pickAndSendFile(conversation.id),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.slate100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.attach_file, size: 18, color: AppColors.slate600),
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
                final senderId = ref.read(profileProvider).activeProfile?.id ?? '';
                ref.read(chatProvider.notifier).sendMessage(
                  conversation.id, v.trim(), senderProfileId: senderId);
                _msgController.clear();
                _scrollToBottom();
              },
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              if (_msgController.text.trim().isEmpty) return;
              final senderId = ref.read(profileProvider).activeProfile?.id ?? '';
              ref.read(chatProvider.notifier).sendMessage(
                conversation.id, _msgController.text.trim(), senderProfileId: senderId);
              _msgController.clear();
              _scrollToBottom();
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

  Future<void> _pickAndSendImage(String conversationId) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    try {
      final senderId = ref.read(profileProvider).activeProfile?.id ?? 'unknown';
      final url = await StorageService.instance.uploadChatMedia(
        conversationId, senderId, bytes, picked.name,
      );
      if (mounted) {
        ref.read(chatProvider.notifier).sendMessage(
          conversationId, '📷 ${picked.name}',
          senderProfileId: senderId,
          contentType: ContentType.image,
          mediaUrl: url,
        );
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Failed to upload image: $e');
    }
  }

  Future<void> _pickAndSendFile(String conversationId) async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) return;
    try {
      final senderId = ref.read(profileProvider).activeProfile?.id ?? 'unknown';
      final url = await StorageService.instance.uploadChatMedia(
        conversationId, senderId, bytes, file.name,
      );
      if (mounted) {
        ref.read(chatProvider.notifier).sendMessage(
          conversationId, '📎 ${file.name}',
          senderProfileId: senderId,
          contentType: ContentType.file,
          mediaUrl: url,
        );
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Failed to upload file: $e');
    }
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
