import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/core/constants/app_strings.dart';
import 'package:merokotha/core/router/app_routes.dart';
import 'package:merokotha/core/utils/validators.dart';
import 'package:merokotha/features/agent/data/agent_repository.dart';
import 'package:merokotha/features/agent/presentation/widgets/agent_bottom_nav.dart';
import 'package:merokotha/features/agent/providers/agent_providers.dart';
import 'package:merokotha/features/auth/providers/auth_provider.dart';
import 'package:merokotha/features/owner/presentation/widgets/owner_widgets.dart';
import 'package:merokotha/shared/models/listing_model.dart';
import 'package:merokotha/shared/widgets/mk_widgets.dart';

const _roomTypes = [
  ('room', 'Room'),
  ('flat', 'Flat'),
  ('apartment', 'Apartment'),
  ('house', 'House'),
  ('office', 'Office'),
  ('shop', 'Shop'),
  ('land', 'Land'),
  ('other', 'Other'),
];

/// Short actionable hint per Storage error code, shown next to the code.
String _photoHint(String code) {
  switch (code) {
    case 'unauthorized':
      return 'Check Storage rules / App Check enforcement.';
    case 'bucket-not-found':
    case 'project-not-found':
      return 'Storage bucket may not be provisioned.';
    case 'quota-exceeded':
      return 'Storage quota exceeded.';
    case 'canceled':
    case 'retry-limit-exceeded':
      return 'Network issue — please retry.';
    default:
      return 'Please try again.';
  }
}

/// Agent posting flow: rooms are posted on behalf of an owner, so the
/// real-owner name and phone are entered manually. The agent's own profile
/// is shown publicly; owner contact stays hidden until an inquiry is
/// accepted (Phase 5).
class AgentUploadScreen extends ConsumerStatefulWidget {
  final ListingModel? listing;

  const AgentUploadScreen({super.key, this.listing});

  @override
  ConsumerState<AgentUploadScreen> createState() => _AgentUploadScreenState();
}

class _AgentUploadScreenState extends ConsumerState<AgentUploadScreen> {
  final _formKey = GlobalKey<FormState>();

  final _ownerNameCtrl = TextEditingController();
  final _ownerPhoneCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _rentCtrl = TextEditingController();
  final _depositCtrl = TextEditingController();
  final _floorCtrl = TextEditingController();
  final _totalFloorsCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _landmarksCtrl = TextEditingController();
  final _callCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  bool _hideName = false;

  String _roomType = 'room';
  FurnishingType _furnishing = FurnishingType.unfurnished;
  List<String> _facilities = [];
  DateTime _availableFrom = DateTime.now();
  LatLng? _pickedLocation;
  final List<File> _pickedImages = [];

  /// Existing photos kept on edit, in display order (first = cover).
  List<String> _keptUrls = [];

  /// Guards the whole submit (validation → Firestore write → photo upload
  /// → navigation) so rapid taps on Publish can only ever post once.
  bool _isSubmitting = false;

  bool get _isEdit => widget.listing != null;

  @override
  void initState() {
    super.initState();
    final l = widget.listing;
    if (l != null) {
      // Legacy fallback: pre-migration listings carry the real-owner name
      // top-level; the restricted subcollection wins when present.
      _ownerNameCtrl.text = l.ownerName;
      _ownerPhoneCtrl.text = l.ownerPhone ?? '';
      _loadOwnerContact(l.id);
      _titleCtrl.text = l.title;
      _rentCtrl.text = l.rentPerMonth.toStringAsFixed(0);
      _depositCtrl.text = l.depositAmount > 0
          ? l.depositAmount.toStringAsFixed(0)
          : '';
      _floorCtrl.text = l.floor.toString();
      _totalFloorsCtrl.text = l.totalFloors.toString();
      _descCtrl.text = l.description;
      _addressCtrl.text = l.address ?? '';
      _landmarksCtrl.text = l.nearbyLandmarks ?? '';
      _callCtrl.text = l.publicPhone ?? '';
      _whatsappCtrl.text = l.whatsappNumber ?? '';
      _hideName = l.hideDisplayName;
      _keptUrls = List.from(l.photoUrls);
      _roomType = l.roomType;
      _furnishing = l.furnishing;
      _facilities = List.from(l.facilities);
      _availableFrom = l.availableFrom;
      if (l.geoPoint != null) {
        _pickedLocation = LatLng(l.geoPoint!.latitude, l.geoPoint!.longitude);
      }
    }
  }

  /// Loads the real-owner contact from the restricted subcollection,
  /// overwriting the legacy top-level fallback. Best-effort: the legacy
  /// values stay on failure.
  Future<void> _loadOwnerContact(String listingId) async {
    try {
      final contact = await ref
          .read(agentRepositoryProvider)
          .getOwnerContact(listingId);
      if (!mounted || contact == null) return;
      setState(() {
        if (contact.name.isNotEmpty) _ownerNameCtrl.text = contact.name;
        if (contact.phone.isNotEmpty) _ownerPhoneCtrl.text = contact.phone;
      });
    } catch (_) {
      // Keep the legacy fallback already in the field.
    }
  }

  @override
  void dispose() {
    _ownerNameCtrl.dispose();
    _ownerPhoneCtrl.dispose();
    _titleCtrl.dispose();
    _rentCtrl.dispose();
    _depositCtrl.dispose();
    _floorCtrl.dispose();
    _totalFloorsCtrl.dispose();
    _descCtrl.dispose();
    _addressCtrl.dispose();
    _landmarksCtrl.dispose();
    _callCtrl.dispose();
    _whatsappCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _availableFrom,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _availableFrom = picked);
  }

  Future<void> _openMapPicker() async {
    LatLng initial = _pickedLocation ?? const LatLng(27.7172, 85.3240);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.whileInUse ||
          perm == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
        );
        if (_pickedLocation == null) {
          initial = LatLng(pos.latitude, pos.longitude);
        }
      }
    } catch (_) {}

    if (!mounted) return;
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(initialLocation: initial),
      ),
    );
    if (result != null) setState(() => _pickedLocation = result);
  }

  Future<List<String>> _uploadImages(String listingId) async {
    final storage = FirebaseStorage.instance;
    final urls = <String>[];
    final stamp = DateTime.now().millisecondsSinceEpoch;
    for (var i = 0; i < _pickedImages.length; i++) {
      final file = _pickedImages[i];
      if (!await file.exists()) {
        debugPrint('Photo upload skipped: file no longer exists: ${file.path}');
        continue;
      }
      try {
        final ref = storage.ref().child('listings/$listingId/photo_${stamp}_$i.jpg');
        final task = await ref.putFile(
          file,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        urls.add(await task.ref.getDownloadURL());
      } on FirebaseException catch (e) {
        debugPrint(
          'Photo upload failed for image $i [${e.code}]: ${e.message}',
        );
        rethrow;
      }
    }
    return urls;
  }

  /// Best-effort deletion of photos removed on edit.
  Future<void> _deleteRemovedPhotos(List<String> removedUrls) async {
    for (final url in removedUrls) {
      try {
        await FirebaseStorage.instance.refFromURL(url).delete();
      } catch (e) {
        debugPrint('Photo delete skipped for $url: $e');
      }
    }
  }

  double get _parsedDeposit =>
      double.tryParse(_depositCtrl.text.trim()) ?? 0;

  GeoPoint? get _resolvedGeoPoint {
    if (_pickedLocation != null) {
      return GeoPoint(_pickedLocation!.latitude, _pickedLocation!.longitude);
    }
    return widget.listing?.geoPoint;
  }

  Future<void> _submit() async {
    // No matter how many times Publish is tapped, only one submit runs.
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;
    if (_resolvedGeoPoint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please pin your room location on the map'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    FocusScope.of(context).unfocus();

    setState(() => _isSubmitting = true);
    try {
      if (_isEdit) {
        await _submitEdit();
      } else {
        await _submitCreate();
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitCreate() async {
    final user = await ref.read(currentUserProvider.future);
    if (user == null) return;

    final id = await ref
        .read(agentUploadProvider.notifier)
        .uploadAgentListing(
          agentId: user.id,
          agentDisplayName: user.name,
          agentPhotoUrl: user.photoUrl,
          ownerName: _ownerNameCtrl.text.trim(),
          ownerPhone: _ownerPhoneCtrl.text.trim(),
          title: _titleCtrl.text.trim(),
          roomType: _roomType,
          rentPerMonth: double.parse(_rentCtrl.text.trim()),
          depositAmount: _parsedDeposit,
          floor: int.tryParse(_floorCtrl.text.trim()) ?? 0,
          totalFloors: int.tryParse(_totalFloorsCtrl.text.trim()) ?? 1,
          furnishing: _furnishing,
          facilities: _facilities,
          description: _descCtrl.text.trim(),
          availableFrom: _availableFrom,
          geoPoint: _resolvedGeoPoint,
          address: _addressCtrl.text.trim(),
          nearbyLandmarks: _landmarksCtrl.text.trim(),
          publicPhone: _callCtrl.text.trim(),
          whatsappNumber: _whatsappCtrl.text.trim(),
          hideDisplayName: _hideName,
        );

    if (!mounted) return;
    if (id != null) {
      if (_pickedImages.isNotEmpty) {
        try {
          final photoUrls = await _uploadImages(id);
          await ref.read(agentRepositoryProvider).updateAgentListing(id, {
            'photoUrls': photoUrls,
          });
        } on FirebaseException catch (e) {
          debugPrint(
            'Agent listing $id photo step failed [${e.code}]: ${e.message}',
          );
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Listing saved, but photo upload failed (${e.code}). ${_photoHint(e.code)}',
              ),
              backgroundColor: AppColors.error,
            ),
          );
          context.go(AppRoutes.agentListings);
          return;
        } catch (e) {
          debugPrint('Agent listing $id photo step failed: $e');
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Listing saved, but photo upload failed.'),
              backgroundColor: AppColors.error,
            ),
          );
          context.go(AppRoutes.agentListings);
          return;
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Listing submitted for review!'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go(AppRoutes.agentListings);
    }
  }

  Future<void> _submitEdit() async {
    final listing = widget.listing!;
    final listingId = listing.id;

    await ref
        .read(agentUploadProvider.notifier)
        .updateExistingAgentListing(
          listingId: listingId,
          agentDisplayName:
              (await ref.read(currentUserProvider.future))?.name ??
              listing.ownerName,
          ownerName: _ownerNameCtrl.text.trim(),
          ownerPhone: _ownerPhoneCtrl.text.trim(),
          title: _titleCtrl.text.trim(),
          roomType: _roomType,
          rentPerMonth: double.parse(_rentCtrl.text.trim()),
          depositAmount: _parsedDeposit,
          floor: int.tryParse(_floorCtrl.text.trim()) ?? 0,
          totalFloors: int.tryParse(_totalFloorsCtrl.text.trim()) ?? 1,
          furnishing: _furnishing,
          facilities: _facilities,
          description: _descCtrl.text.trim(),
          availableFrom: _availableFrom,
          geoPoint: _resolvedGeoPoint,
          address: _addressCtrl.text.trim(),
          nearbyLandmarks: _landmarksCtrl.text.trim(),
          publicPhone: _callCtrl.text.trim(),
          whatsappNumber: _whatsappCtrl.text.trim(),
          hideDisplayName: _hideName,
        );

    if (!mounted) return;
    if (ref.read(agentUploadProvider).success) {
      final removed = listing.photoUrls
          .where((u) => !_keptUrls.contains(u))
          .toList();
      if (removed.isNotEmpty) await _deleteRemovedPhotos(removed);

      if (removed.isNotEmpty || _pickedImages.isNotEmpty) {
        try {
          final uploaded = await _uploadImages(listingId);
          await ref.read(agentRepositoryProvider).updateAgentListing(
            listingId,
            {
              'photoUrls': [..._keptUrls, ...uploaded],
            },
          );
        } on FirebaseException catch (e) {
          debugPrint(
            'Agent listing $listingId photo update failed [${e.code}]: ${e.message}',
          );
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Listing updated, but photo upload failed (${e.code}). ${_photoHint(e.code)}',
              ),
              backgroundColor: AppColors.error,
            ),
          );
          context.go(AppRoutes.agentListings);
          return;
        } catch (e) {
          debugPrint('Agent listing $listingId photo update failed: $e');
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Listing updated, but photo upload failed.'),
              backgroundColor: AppColors.error,
            ),
          );
          context.go(AppRoutes.agentListings);
          return;
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Changes saved — sent back for review.'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go(AppRoutes.agentListings);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.backgroundSecondary,
        appBar: MkAppBar(title: 'Post a room', showBack: false),
        body: MkLoading(),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.backgroundSecondary,
        appBar: const MkAppBar(title: 'Post a room', showBack: false),
        body: MkErrorWidget(message: e.toString()),
        bottomNavigationBar: const AgentBottomNav(currentIndex: 2),
      ),
      data: (user) {
        if (user?.isVerifiedAgent != true) {
          return Scaffold(
            backgroundColor: AppColors.backgroundSecondary,
            appBar: const MkAppBar(title: 'Post a room', showBack: false),
            body: const Padding(
              padding: EdgeInsets.all(20),
              child: MkEmptyState(
                icon: Icons.hourglass_top_rounded,
                title: 'Awaiting admin verification',
                subtitle:
                    'You can browse rooms for now. Posting unlocks after an admin verifies your agent account.',
              ),
            ),
            bottomNavigationBar: const AgentBottomNav(currentIndex: 2),
          );
        }
        return _buildForm(context, ref);
      },
    );
  }

  Widget _buildForm(BuildContext context, WidgetRef ref) {
    final uploadState = ref.watch(agentUploadProvider);
    final locationSet =
        _pickedLocation != null ||
        (_isEdit && widget.listing?.geoPoint != null);

    ref.listen(agentUploadProvider, (_, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: MkAppBar(
        title: _isEdit ? 'Edit listing' : 'Post a room',
        onBack: () => context.pop(),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  color: AppColors.infoLight,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  border: Border.all(color: AppColors.info),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.support_agent_rounded,
                      size: 20,
                      color: AppColors.info,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Posting on behalf of an owner. Your agent profile is shown publicly; the real-owner contact below stays private and is never displayed on the listing.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: AppColors.grey800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              ListingPhotoManager(
                existingUrls: _keptUrls,
                onExistingChanged: (urls) =>
                    setState(() => _keptUrls = urls),
                newImages: _pickedImages,
                onNewChanged: (imgs) => setState(() {
                  _pickedImages
                    ..clear()
                    ..addAll(imgs);
                }),
              ),
              const SizedBox(height: 20),

              UploadFormCard(
                title: 'Property owner (private)',
                children: [
                  MkTextField(
                    label: 'Real owner name',
                    hint: 'e.g. Ram Bahadur Thapa',
                    controller: _ownerNameCtrl,
                    validator: Validators.name,
                    textCapitalization: TextCapitalization.words,
                    prefixIcon: const Icon(
                      Icons.person_outline_rounded,
                      size: 18,
                      color: AppColors.grey400,
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),
                  MkTextField(
                    label: 'Real owner phone',
                    hint: '98XXXXXXXX',
                    controller: _ownerPhoneCtrl,
                    validator: Validators.phone,
                    keyboardType: TextInputType.phone,
                    prefixIcon: const Icon(
                      Icons.phone_outlined,
                      size: 18,
                      color: AppColors.grey400,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              UploadFormCard(
                title: 'Basic information',
                children: [
                  MkTextField(
                    label: AppStrings.listingTitle,
                    hint: AppStrings.listingTitleHint,
                    controller: _titleCtrl,
                    validator: Validators.required,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: AppSizes.md),

                  const UploadFormLabel('Room type'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _roomType,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.grey400,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                    items: _roomTypes
                        .map(
                          (t) => DropdownMenuItem(
                            value: t.$1,
                            child: Text(
                              t.$2,
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppColors.grey900,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _roomType = v ?? 'room'),
                  ),

                  const SizedBox(height: AppSizes.md),
                  const UploadFormLabel('Furnishing'),
                  const SizedBox(height: 8),
                  SegmentSelector<FurnishingType>(
                    values: FurnishingType.values,
                    selected: _furnishing,
                    label: (t) {
                      switch (t) {
                        case FurnishingType.furnished:
                          return 'Furnished';
                        case FurnishingType.semiFurnished:
                          return 'Semi';
                        case FurnishingType.unfurnished:
                          return 'Unfurnished';
                      }
                    },
                    onChanged: (v) => setState(() => _furnishing = v),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              UploadFormCard(
                title: 'Pricing',
                children: [
                  MkPriceField(
                    label: 'Rent / month',
                    hint: '8000',
                    controller: _rentCtrl,
                    validator: Validators.price,
                  ),
                  const SizedBox(height: AppSizes.md),
                  MkPriceField(
                    label: 'Deposit (optional)',
                    hint: '0',
                    controller: _depositCtrl,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              UploadFormCard(
                title: 'Contact & privacy',
                children: [
                  MkTextField(
                    label: 'Public call number (optional)',
                    hint: '98XXXXXXXX',
                    controller: _callCtrl,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: AppSizes.md),
                  MkTextField(
                    label: 'WhatsApp number (optional)',
                    hint: '98XXXXXXXX',
                    controller: _whatsappCtrl,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: AppSizes.md),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Hide public name',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text(
                      'Your agent profile shows a generic label instead.',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: _hideName,
                    onChanged: (v) => setState(() => _hideName = v),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              UploadFormCard(
                title: 'Building details',
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: MkTextField(
                          label: 'Floor no.',
                          hint: '2',
                          controller: _floorCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MkTextField(
                          label: 'Total floors',
                          hint: '4',
                          controller: _totalFloorsCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.md),
                  const UploadFormLabel('Available from'),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 18,
                            color: AppColors.grey400,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${_availableFrom.day}/${_availableFrom.month}/${_availableFrom.year}',
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.grey900,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: AppColors.grey400,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              UploadFormCard(
                title: 'Facilities',
                children: [
                  FacilitiesSelector(
                    selected: _facilities,
                    onChanged: (v) => setState(() => _facilities = v),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              UploadFormCard(
                title: 'Description',
                children: [
                  MkTextField(
                    label: 'About this room',
                    hint:
                        'Describe the room, neighbourhood, transport access...',
                    controller: _descCtrl,
                    validator: Validators.description,
                    maxLines: 4,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              UploadFormCard(
                title: 'Location',
                children: [
                  MkTextField(
                    label: 'Address / area',
                    hint: 'e.g. Baneshwor, Kathmandu',
                    controller: _addressCtrl,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: AppSizes.md),
                  MkTextField(
                    label: 'Nearby landmarks (optional)',
                    hint: 'e.g. Near Tribhuvan University gate',
                    controller: _landmarksCtrl,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: AppSizes.md),
                  GestureDetector(
                    onTap: _openMapPicker,
                    child: Container(
                      padding: const EdgeInsets.all(AppSizes.md),
                      decoration: BoxDecoration(
                        color: locationSet
                            ? AppColors.primaryLight
                            : AppColors.backgroundSecondary,
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        border: Border.all(
                          color: locationSet
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            locationSet
                                ? Icons.location_on_rounded
                                : Icons.add_location_alt_outlined,
                            color: locationSet
                                ? AppColors.primary
                                : AppColors.grey400,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              locationSet
                                  ? _pickedLocation != null
                                        ? 'Pinned: ${_pickedLocation!.latitude.toStringAsFixed(4)}, ${_pickedLocation!.longitude.toStringAsFixed(4)}'
                                        : 'Location already set — tap to update'
                                  : AppStrings.pinLocation,
                              style: TextStyle(
                                fontSize: 14,
                                color: locationSet
                                    ? AppColors.primary
                                    : AppColors.grey600,
                                fontWeight: locationSet
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: locationSet
                                ? AppColors.primary
                                : AppColors.grey400,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              MkButton(
                label: _isEdit ? 'Save changes' : AppStrings.publishListing,
                onPressed: (_isSubmitting || uploadState.isLoading)
                    ? null
                    : _submit,
                isLoading: uploadState.isLoading || _isSubmitting,
                prefixIcon: _isEdit
                    ? Icons.save_rounded
                    : Icons.publish_rounded,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
