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
import 'package:merokotha/shared/widgets/mk_app_bar.dart';
import 'package:merokotha/shared/widgets/mk_button.dart';
import 'package:merokotha/shared/widgets/mk_text_field.dart';
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
  final _floorCtrl = TextEditingController();
  final _totalFloorsCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _landmarksCtrl = TextEditingController();

  String _roomType = 'room';
  FurnishingType _furnishing = FurnishingType.unfurnished;
  List<String> _facilities = [];
  DateTime _availableFrom = DateTime.now();
  LatLng? _pickedLocation;
  final List<File> _pickedImages = [];

  bool get _isEdit => widget.listing != null;

  @override
  void initState() {
    super.initState();
    final l = widget.listing;
    if (l != null) {
      _ownerNameCtrl.text = l.ownerName;
      _ownerPhoneCtrl.text = l.ownerPhone ?? '';
      _titleCtrl.text = l.title;
      _rentCtrl.text = l.rentPerMonth.toStringAsFixed(0);
      _floorCtrl.text = l.floor.toString();
      _totalFloorsCtrl.text = l.totalFloors.toString();
      _descCtrl.text = l.description;
      _addressCtrl.text = l.address ?? '';
      _landmarksCtrl.text = l.nearbyLandmarks ?? '';
      _roomType = l.roomType;
      _furnishing = l.furnishing;
      _facilities = List.from(l.facilities);
      _availableFrom = l.availableFrom;
      if (l.geoPoint != null) {
        _pickedLocation = LatLng(l.geoPoint!.latitude, l.geoPoint!.longitude);
      }
    }
  }

  @override
  void dispose() {
    _ownerNameCtrl.dispose();
    _ownerPhoneCtrl.dispose();
    _titleCtrl.dispose();
    _rentCtrl.dispose();
    _floorCtrl.dispose();
    _totalFloorsCtrl.dispose();
    _descCtrl.dispose();
    _addressCtrl.dispose();
    _landmarksCtrl.dispose();
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
    for (var i = 0; i < _pickedImages.length; i++) {
      final ref = storage.ref().child('listings/$listingId/image_$i.jpg');
      final task = await ref.putFile(
        _pickedImages[i],
        SettableMetadata(contentType: 'image/jpeg'),
      );
      urls.add(await task.ref.getDownloadURL());
    }
    return urls;
  }

  GeoPoint? get _resolvedGeoPoint {
    if (_pickedLocation != null) {
      return GeoPoint(_pickedLocation!.latitude, _pickedLocation!.longitude);
    }
    return widget.listing?.geoPoint;
  }

  Future<void> _submit() async {
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

    if (_isEdit) {
      await _submitEdit();
    } else {
      await _submitCreate();
    }
  }

  Future<void> _submitCreate() async {
    final user = await ref.read(currentUserProvider.future);
    if (user == null) return;

    final id = await ref
        .read(agentUploadProvider.notifier)
        .uploadAgentListing(
          agentId: user.id,
          agentPhotoUrl: user.photoUrl,
          ownerName: _ownerNameCtrl.text.trim(),
          ownerPhone: _ownerPhoneCtrl.text.trim(),
          title: _titleCtrl.text.trim(),
          roomType: _roomType,
          rentPerMonth: double.parse(_rentCtrl.text.trim()),
          depositAmount: 0,
          floor: int.tryParse(_floorCtrl.text.trim()) ?? 0,
          totalFloors: int.tryParse(_totalFloorsCtrl.text.trim()) ?? 1,
          furnishing: _furnishing,
          facilities: _facilities,
          description: _descCtrl.text.trim(),
          availableFrom: _availableFrom,
          geoPoint: _resolvedGeoPoint,
          address: _addressCtrl.text.trim(),
          nearbyLandmarks: _landmarksCtrl.text.trim(),
        );

    if (!mounted) return;
    if (id != null) {
      if (_pickedImages.isNotEmpty) {
        try {
          final photoUrls = await _uploadImages(id);
          await ref.read(agentRepositoryProvider).updateAgentListing(id, {
            'photoUrls': photoUrls,
          });
        } catch (_) {
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
          content: Text('Listing published!'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go(AppRoutes.agentListings);
    }
  }

  Future<void> _submitEdit() async {
    final listingId = widget.listing!.id;

    await ref
        .read(agentUploadProvider.notifier)
        .updateExistingAgentListing(
          listingId: listingId,
          ownerName: _ownerNameCtrl.text.trim(),
          ownerPhone: _ownerPhoneCtrl.text.trim(),
          title: _titleCtrl.text.trim(),
          roomType: _roomType,
          rentPerMonth: double.parse(_rentCtrl.text.trim()),
          depositAmount: 0,
          floor: int.tryParse(_floorCtrl.text.trim()) ?? 0,
          totalFloors: int.tryParse(_totalFloorsCtrl.text.trim()) ?? 1,
          furnishing: _furnishing,
          facilities: _facilities,
          description: _descCtrl.text.trim(),
          availableFrom: _availableFrom,
          geoPoint: _resolvedGeoPoint,
          address: _addressCtrl.text.trim(),
          nearbyLandmarks: _landmarksCtrl.text.trim(),
        );

    if (!mounted) return;
    if (ref.read(agentUploadProvider).success) {
      if (_pickedImages.isNotEmpty) {
        try {
          final photoUrls = await _uploadImages(listingId);
          await ref.read(agentRepositoryProvider).updateAgentListing(listingId, {
            'photoUrls': photoUrls,
          });
        } catch (_) {
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
          content: Text('Listing updated!'),
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
    final existingPhotos = widget.listing?.photoUrls ?? [];
    final locationSet =
        _pickedLocation != null || (_isEdit && widget.listing?.geoPoint != null);

    ref.listen(agentUploadProvider, (_, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: AppColors.error),
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
                        'Posting on behalf of an owner. Your agent profile is shown publicly; the owner contact below stays hidden until you accept an inquiry.',
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

              ListingPhotoPicker(
                images: _pickedImages,
                onChanged: (imgs) => setState(() {
                  _pickedImages
                    ..clear()
                    ..addAll(imgs);
                }),
                existingPhotoUrl: existingPhotos.isNotEmpty
                    ? existingPhotos.first
                    : null,
                existingPhotoCount: existingPhotos.length,
              ),
              const SizedBox(height: 20),

              UploadFormCard(
                title: 'Property owner',
                children: [
                  MkTextField(
                    label: 'Owner name',
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
                    label: 'Owner phone',
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
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.grey400),
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
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
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
                onPressed: _submit,
                isLoading: uploadState.isLoading,
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
