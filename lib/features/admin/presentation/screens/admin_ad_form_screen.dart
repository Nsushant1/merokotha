import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/features/admin/presentation/widgets/admin_nav.dart';
import 'package:merokotha/features/admin/providers/ads_providers.dart';
import 'package:merokotha/shared/models/ad_model.dart';
import 'package:merokotha/shared/widgets/mk_button.dart';
import 'package:merokotha/shared/widgets/mk_text_field.dart';

class AdminAdFormScreen extends ConsumerStatefulWidget {
  final AdModel? ad;
  const AdminAdFormScreen({super.key, this.ad});

  @override
  ConsumerState<AdminAdFormScreen> createState() => _AdminAdFormScreenState();
}

class _AdminAdFormScreenState extends ConsumerState<AdminAdFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _subtitle;
  late final TextEditingController _listingId;
  late final TextEditingController _externalUrl;
  late final TextEditingController _priority;
  late String _placement;
  late String _linkType;
  late bool _isActive;
  File? _pickedImage;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final a = widget.ad;
    _title = TextEditingController(text: a?.title ?? '');
    _subtitle = TextEditingController(text: a?.subtitle ?? '');
    _listingId = TextEditingController(text: a?.listingId ?? '');
    _externalUrl = TextEditingController(text: a?.externalUrl ?? '');
    _priority = TextEditingController(text: '${a?.priority ?? 0}');
    _placement = a?.placement ?? 'all';
    _linkType = a?.linkType ?? 'none';
    _isActive = a?.isActive ?? true;
  }

  @override
  void dispose() {
    _title.dispose();
    _subtitle.dispose();
    _listingId.dispose();
    _externalUrl.dispose();
    _priority.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    if (picked != null) setState(() => _pickedImage = File(picked.path));
  }

  Future<String> _uploadImage(String adId) async {
    final ref = FirebaseStorage.instance.ref().child('ads/$adId.jpg');
    final task = await ref.putFile(
      _pickedImage!,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return task.ref.getDownloadURL();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.ad == null && _pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick a banner image')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final notifier = ref.read(adsActionProvider.notifier);
      final now = DateTime.now();
      final data = <String, dynamic>{
        'title': _title.text.trim(),
        'subtitle': _subtitle.text.trim(),
        'placement': _placement,
        'status': _isActive ? 'active' : 'paused',
        'priority': int.tryParse(_priority.text.trim()) ?? 0,
        'linkType': _linkType,
        'listingId': _linkType == 'listing' ? _listingId.text.trim() : null,
        'externalUrl': _linkType == 'external'
            ? _externalUrl.text.trim()
            : null,
      };

      if (widget.ad == null) {
        // Create doc first so Storage path uses the real ad id.
        final id = await notifier.create({
          ...data,
          'imageUrl': '',
          'createdAt': Timestamp.fromDate(now),
        });
        if (id == null) throw Exception('Create failed');
        final url = await _uploadImage(id);
        await notifier.update(id, {'imageUrl': url});
      } else {
        var imageUrl = widget.ad!.imageUrl;
        if (_pickedImage != null) {
          imageUrl = await _uploadImage(widget.ad!.id);
        }
        await notifier.update(widget.ad!.id, {...data, 'imageUrl': imageUrl});
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.ad != null;
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AdminAppBar(
        title: isEdit ? 'Edit banner ad' : 'New banner ad',
        showBack: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.pagePadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                    border: Border.all(color: AppColors.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _pickedImage != null
                      ? Image.file(_pickedImage!, fit: BoxFit.cover)
                      : widget.ad != null && widget.ad!.imageUrl.isNotEmpty
                      ? Image.network(widget.ad!.imageUrl, fit: BoxFit.cover)
                      : const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_a_photo_outlined),
                              SizedBox(height: 8),
                              Text('Tap to pick banner image'),
                            ],
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              MkTextField(
                controller: _title,
                label: 'Title',
                hint: 'Dashain offer — 20% off',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              MkTextField(
                controller: _subtitle,
                label: 'Subtitle (optional)',
                hint: 'Rooms, flats & houses across Nepal',
              ),
              const SizedBox(height: 12),
              const Text(
                'Placement',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['all', 'landing', 'home']
                    .map(
                      (p) => ChoiceChip(
                        label: Text(p),
                        selected: _placement == p,
                        onSelected: (_) => setState(() => _placement = p),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              const Text(
                'Link action',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['none', 'listing', 'external']
                    .map(
                      (t) => ChoiceChip(
                        label: Text(t),
                        selected: _linkType == t,
                        onSelected: (_) => setState(() => _linkType = t),
                      ),
                    )
                    .toList(),
              ),
              if (_linkType == 'listing') ...[
                const SizedBox(height: 12),
                MkTextField(
                  controller: _listingId,
                  label: 'Listing ID',
                  hint: 'Paste room listing document id',
                  validator: (v) =>
                      _linkType == 'listing' && (v == null || v.trim().isEmpty)
                      ? 'Required for listing link'
                      : null,
                ),
              ],
              if (_linkType == 'external') ...[
                const SizedBox(height: 12),
                MkTextField(
                  controller: _externalUrl,
                  label: 'External URL',
                  hint: 'https://…',
                  validator: (v) =>
                      _linkType == 'external' && (v == null || v.trim().isEmpty)
                      ? 'Required for external link'
                      : null,
                ),
              ],
              const SizedBox(height: 12),
              MkTextField(
                controller: _priority,
                label: 'Priority (higher shows first)',
                hint: '0',
                keyboardType: TextInputType.number,
              ),
              SwitchListTile(
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
                title: const Text('Active'),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 8),
              MkButton(
                label: isEdit ? 'Save changes' : 'Publish banner',
                onPressed: _save,
                isLoading: _saving,
                variant: MkButtonVariant.accent,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
