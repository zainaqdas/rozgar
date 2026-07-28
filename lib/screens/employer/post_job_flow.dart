import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/translations.dart';
import '../../utils/formatters.dart';
import '../../data/categories.dart';
import '../../models/job.dart';
import '../../models/location_point.dart';
import '../../services/ai_service.dart';
import '../../widgets/location_pin_drop.dart';

class PostJobFlow extends ConsumerStatefulWidget {
  final VoidCallback onComplete;

  const PostJobFlow({
    super.key,
    required this.onComplete,
  });

  @override
  ConsumerState<PostJobFlow> createState() => _PostJobFlowState();
}

class _PostJobFlowState extends ConsumerState<PostJobFlow> {
  int _step = 1; // 1-4

  final _descController = TextEditingController();
  final _budgetController = TextEditingController(text: '0');
  bool _isAiParsing = false;
  bool _aiSuccess = false;

  // Parsed job state (editable)
  String _selectedCategoryId = 'home-plumbing';
  String _title = '';
  JobUrgency _urgency = JobUrgency.scheduled;
  double _budgetAmount = 0;
  BudgetType _budgetType = BudgetType.fixed;
  double _estimatedDuration = 1;
  List<String> _requiredSkills = [];
  LocationPoint _confirmedLocation = const LocationPoint(
    lat: 31.5204,
    lng: 74.3587,
    address: '',
    city: '',
  );

  @override
  void dispose() {
    _descController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _runAiParse() async {
    if (_descController.text.trim().isEmpty) return;
    setState(() => _isAiParsing = true);

    Map<String, dynamic> summary;
    try {
      summary = await AIService.parseJob(_descController.text);
    } catch (e) {
      debugPrint('AI parse failed: $e');
      if (mounted) setState(() => _isAiParsing = false);
      return;
    }
    final catMatch = seededCategories.where((c) =>
        c.nameEn.toLowerCase().contains((summary['category'] as String? ?? '').toLowerCase())).firstOrNull;

    if (mounted) {
      setState(() {
        if (catMatch != null) _selectedCategoryId = catMatch.id;
        if (summary['urgency'] != null) {
          _urgency = summary['urgency'] == 'instant'
              ? JobUrgency.instant
              : summary['urgency'] == 'scheduled'
                  ? JobUrgency.scheduled
                  : JobUrgency.today;
        }
        if (summary['suggestedBudget'] != null) {
          _budgetAmount = (summary['suggestedBudget'] as num?)?.toDouble() ?? 0;
          _budgetController.text = _budgetAmount.toInt().toString();
        }
        if (summary['estimatedDuration'] != null) {
          _estimatedDuration = (summary['estimatedDuration'] as num?)?.toDouble() ?? 1;
        }
        if (summary['requiredSkills'] != null) {
          _requiredSkills = (summary['requiredSkills'] as List)
              .map((e) => e.toString())
              .toList();
        }
        _title = _descController.text.length > 48
            ? '${_descController.text.substring(0, 48)}...'
            : _descController.text;
        _aiSuccess = true;
        _isAiParsing = false;
      });
    }
  }

  void _postJob() {
    final empProfile = ref.read(profileProvider).employerProfile;
    if (empProfile == null) return;

    ref.read(jobProvider.notifier).addJob(
      employerProfileId: empProfile.id,
      categoryId: _selectedCategoryId,
      title: _title.isNotEmpty ? _title : _descController.text,
      description: _descController.text,
      aiExtractedSummary: AIExtractedSummary(
        category: seededCategories
                .where((c) => c.id == _selectedCategoryId)
                .firstOrNull
                ?.nameEn ??
            'Service',
        urgency: _urgency,
        suggestedBudget: _budgetAmount,
        estimatedDuration: _estimatedDuration,
        requiredSkills: _requiredSkills,
      ),
      budgetAmount: _budgetAmount,
      budgetType: _budgetType,
      pinLocation: _confirmedLocation,
      urgency: _urgency,
    );
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(settingsProvider).language;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppTranslations.t('postJobCTA', lang),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.slate800,
                      ),
                    ),
                    Text(
                      'Step $_step of 4',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.slate500,
                      ),
                    ),
                  ],
                ),
              ),
              // Step indicators
              Row(
                children: List.generate(4, (i) {
                  final isActive = i < _step;
                  return Container(
                    width: 24,
                    height: 6,
                    margin: const EdgeInsets.only(left: 4),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.teal600
                          : AppColors.slate200,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Step Content
          switch (_step) {
            1 => _buildStep1(lang),
            2 => _buildStep2(lang),
            3 => _buildStep3(lang),
            4 => _buildStep4(lang),
            _ => const SizedBox.shrink(),
          },
        ],
      ),
    );
  }

  // STEP 1: Description + AI
  Widget _buildStep1(LanguageOption lang) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppTranslations.t('postJobTitle', lang),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.slate800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Type naturally in Urdu or English. AI will pre-fill category, budget & urgency!',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.slate500,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: TextField(
              controller: _descController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText:
                    'Describe the work you need done...',
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.maxFinite,
            child: ElevatedButton(
              onPressed: _isAiParsing ? null : _runAiParse,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal50,
                foregroundColor: AppColors.teal800,
                elevation: 0,
                side: const BorderSide(color: AppColors.teal200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: AppColors.teal600,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _isAiParsing
                          ? AppTranslations.t('aiParsing', lang)
                          : 'AI Extract & Pre-fill Details',
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_aiSuccess) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.teal50,
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: AppColors.teal200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle,
                      size: 16, color: AppColors.teal600),
                  const SizedBox(width: 8),
                  Text(
                    AppTranslations.t('aiParsedSuccess', lang),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.teal800,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Category Selector
          DropdownButtonFormField<String>(
            initialValue: _selectedCategoryId,
            decoration: InputDecoration(
              labelText: AppTranslations.t('category', lang),
            ),
            items: seededCategories.map((cat) {
              return DropdownMenuItem(
                value: cat.id,
                child: Text(
                  '${cat.nameEn} (${cat.nameUr})',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              );
            }).toList(),
            onChanged: (v) {
              if (v != null) setState(() => _selectedCategoryId = v);
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.maxFinite,
            child: ElevatedButton(
              onPressed: () => setState(() => _step = 2),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Continue to Location Pin Drop'),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // STEP 2: Location Pin Drop (Google Maps ride-app style)
  Widget _buildStep2(LanguageOption lang) {
    final screenHeight = MediaQuery.of(context).size.height;
    return SizedBox(
      height: screenHeight * 0.75,
      child: LocationPinDrop(
        initialLocation: _confirmedLocation,
        language: lang,
        confirmBtnText: 'Confirm Job Location',
        onConfirmLocation: (loc) {
          setState(() {
            _confirmedLocation = loc;
            _step = 3;
          });
        },
      ),
    );
  }

  // STEP 3: Budget & Scheduling
  Widget _buildStep3(LanguageOption lang) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Set Budget & Urgency',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.slate800,
            ),
          ),
          const SizedBox(height: 16),

          // Urgency
          Text(
            AppTranslations.t('urgency', lang),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.slate700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: JobUrgency.values.map((u) {
              final isActive = _urgency == u;
              final label = switch (u) {
                JobUrgency.instant => '⚡ Instant',
                JobUrgency.today => '📅 Today',
                JobUrgency.scheduled => '🕒 Scheduled',
              };
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _urgency = u),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.teal600
                          : AppColors.slate50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isActive
                            ? AppColors.teal600
                            : AppColors.slate200,
                      ),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isActive
                            ? Colors.white
                            : AppColors.slate600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Budget Amount
          TextField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Offered Budget (PKR)',
              prefixText: 'Rs. ',
              prefixStyle: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.teal700,
              ),
            ),
            controller: _budgetController,
            onChanged: (v) =>
                _budgetAmount = double.tryParse(v) ?? 0,
          ),
          const SizedBox(height: 16),

          // Budget Type
          Text(
            AppTranslations.t('budgetType', lang),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.slate700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: BudgetType.values.map((bt) {
              final isActive = _budgetType == bt;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _budgetType = bt),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.teal50
                          : AppColors.slate50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isActive
                            ? AppColors.teal600
                            : AppColors.slate200,
                      ),
                    ),
                    child: Text(
                      AppTranslations.t(bt.name, lang),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isActive
                            ? AppColors.teal900
                            : AppColors.slate600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.maxFinite,
            child: ElevatedButton(
              onPressed: () => setState(() => _step = 4),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Review & Post Job'),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // STEP 4: Review
  Widget _buildStep4(LanguageOption lang) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Review Job Posting',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.slate800,
            ),
          ),
          const SizedBox(height: 16),
          // Summary
          Container(
            width: double.maxFinite,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.slate50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.slate200),
            ),
            child: Column(
              children: [
                _summaryRow('Category:',
                    seededCategories
                            .where((c) =>
                                c.id == _selectedCategoryId)
                            .firstOrNull
                            ?.nameEn ??
                        ''),
                const SizedBox(height: 8),
                _summaryRow('Urgency:', _urgency.name),
                const SizedBox(height: 8),
                _summaryRow('Budget:',
                    formatPkr(_budgetAmount)),
                const SizedBox(height: 8),
                _summaryRow(
                    'Location:', _confirmedLocation.address),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.teal50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.teal200),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline,
                    size: 16, color: AppColors.teal600),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Posting will immediately alert nearby online workers in Lahore via push notification!',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.teal900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.maxFinite,
            child: ElevatedButton(
              onPressed: _postJob,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 18),
                  SizedBox(width: 8),
                  Text('Post Job & Alert Nearby Workers'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.slate500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.slate800,
          ),
        ),
      ],
    );
  }
}
