import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/animal_photo_avatar.dart';
import '../../core/widgets/error_retry_card.dart';
import '../../core/widgets/sheep_hoof_icon.dart';
import '../../providers/animals_provider.dart';

class AddAnimalScreen extends ConsumerStatefulWidget {
  const AddAnimalScreen({super.key});

  @override
  ConsumerState<AddAnimalScreen> createState() => _AddAnimalScreenState();
}

class _AddAnimalScreenState extends ConsumerState<AddAnimalScreen> {
  final _formKey = GlobalKey<FormState>();

  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _tagController = TextEditingController();
  final _lineageController = TextEditingController();
  final _fatherIdController = TextEditingController();
  final _motherIdController = TextEditingController();
  final _weightController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();

  int? _selectedBreedId;
  int? _selectedSectorId;
  String _selectedSex = 'female';
  String _selectedOrigin = 'purchase';
  DateTime? _selectedBirthDate;
  String? _photoDataUrl;
  bool _isSubmitting = false;

  Future<void> _pickPhoto() async {
    final res = await showAnimalPhotoPickerSheet(
      context,
      hasCurrentPhoto: _photoDataUrl != null,
    );
    if (res == null) return;
    if (res.removed) {
      setState(() => _photoDataUrl = null);
    } else if (res.dataUrl != null) {
      setState(() => _photoDataUrl = res.dataUrl);
    }
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? now,
      firstDate: DateTime(now.year - 15),
      lastDate: now,
      helpText: 'Sélectionner la date de naissance',
      cancelText: 'Annuler',
      confirmText: 'Valider',
    );
    if (picked != null) {
      setState(() => _selectedBirthDate = picked);
    }
  }

  String _formatIsoDate(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _tagController.dispose();
    _lineageController.dispose();
    _fatherIdController.dispose();
    _motherIdController.dispose();
    _weightController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBreedId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une race')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final payload = {
        'id': _idController.text.trim(),
        'name': _nameController.text.trim(),
        'physical_tag': _tagController.text.trim().isEmpty
            ? null
            : _tagController.text.trim(),
        'photo_url': _photoDataUrl,
        'breed_id': _selectedBreedId,
        'sex': _selectedSex,
        'birth_date': _selectedBirthDate != null
            ? _formatIsoDate(_selectedBirthDate!)
            : null,
        'origin': _selectedOrigin,
        'current_sector_id': _selectedSectorId,
        'current_weight_kg': double.tryParse(
          _weightController.text.replaceAll(',', '.'),
        ),
        'purchase_price_cfa': double.tryParse(
          _priceController.text.replaceAll(',', '.'),
        ),
        'body_condition': 'normal',
        'status': 'active',
        'lineage': _lineageController.text.trim().isEmpty
            ? null
            : _lineageController.text.trim(),
        'father_id': _fatherIdController.text.trim().isEmpty
            ? null
            : _fatherIdController.text.trim(),
        'mother_id': _motherIdController.text.trim().isEmpty
            ? null
            : _motherIdController.text.trim(),
        'notes': _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      };

      final created = await ref
          .read(animalActionsServiceProvider)
          .createAnimal(payload);
      ref.read(animalsListProvider.notifier).upsertAnimal(created);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ovin enregistré avec succès')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final breedsAsync = ref.watch(breedsProvider);
    final sectorsAsync = ref.watch(sectorsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Enregistrer un Ovin')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Photo de l'ovin (optionnel)
            Center(
              child: GestureDetector(
                onTap: _pickPhoto,
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryContainer,
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              width: 2,
                            ),
                          ),
                          child: AnimalPhotoImage(
                            photoUrl: _photoDataUrl,
                            size: 96,
                            fallback: const Center(
                              child: Icon(
                                LucideIcons.camera,
                                size: 32,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Icon(
                              _photoDataUrl != null
                                  ? LucideIcons.pencil
                                  : LucideIcons.plus,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _photoDataUrl != null
                          ? 'Modifier la photo de l\'ovin'
                          : 'Ajouter une photo (optionnel)',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Identifiants
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Identification',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _idController,
                      decoration: const InputDecoration(
                        labelText: 'Identifiant interne unique *',
                        hintText: 'ex: NK-2026-02 ou LDM-01',
                        prefixIcon: Icon(LucideIcons.badgeCheck),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Identifiant obligatoire'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom de l\'animal *',
                        hintText: 'ex: Ndeye Khady, Gorgui...',
                        prefixIcon: Padding(
                          padding: EdgeInsets.all(13),
                          child: SheepHoofIcon(size: 20),
                        ),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Nom obligatoire'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _tagController,
                      decoration: const InputDecoration(
                        labelText: 'Numéro de boucle / tag physique',
                        hintText: 'ex: SN-DKR-045',
                        prefixIcon: Icon(LucideIcons.tag),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _lineageController,
                      decoration: const InputDecoration(
                        labelText: 'Lignée / Sang (Pedigree)',
                        hintText: 'ex: Lignée Serigne, Lignée Nabou Jr...',
                        prefixIcon: Icon(LucideIcons.dna),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _fatherIdController,
                            decoration: const InputDecoration(
                              labelText: 'ID Père (Bélier)',
                              hintText: 'ex: LDM-01',
                              prefixIcon: Icon(LucideIcons.mars),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _motherIdController,
                            decoration: const InputDecoration(
                              labelText: 'ID Mère (Brebis)',
                              hintText: 'ex: LDM-02',
                              prefixIcon: Icon(LucideIcons.venus),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Race & Sexe
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Race & Sexe',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    breedsAsync.when(
                      data: (breeds) {
                        return DropdownButtonFormField<int>(
                          initialValue: _selectedBreedId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Race ovine *',
                            prefixIcon: Icon(LucideIcons.folders),
                          ),
                          items: breeds.map((b) {
                            return DropdownMenuItem<int>(
                              value: b.id,
                              child: Text(
                                b.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) =>
                              setState(() => _selectedBreedId = val),
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => ErrorRetryCard(
                        compact: true,
                        message: 'Impossible de charger les races : $e',
                        onRetry: () => ref.refresh(breedsProvider),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedSex,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Sexe *',
                        prefixIcon: Icon(LucideIcons.venusAndMars),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'female',
                          child: Text(
                            'Femelle (Brebis)',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'male',
                          child: Text(
                            'Mâle (Bélier)',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      onChanged: (val) =>
                          setState(() => _selectedSex = val ?? 'female'),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: _pickBirthDate,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Date de naissance (optionnel)',
                          prefixIcon: const Icon(LucideIcons.calendarDays),
                          suffixIcon: _selectedBirthDate != null
                              ? IconButton(
                                  icon: const Icon(LucideIcons.x, size: 18),
                                  tooltip: 'Effacer la date',
                                  onPressed: () =>
                                      setState(() => _selectedBirthDate = null),
                                )
                              : const Icon(LucideIcons.chevronDown, size: 18),
                        ),
                        child: Text(
                          _selectedBirthDate != null
                              ? Formatters.formatDate(_selectedBirthDate)
                              : 'Non renseignée (cliquer pour choisir)',
                          style: TextStyle(
                            color: _selectedBirthDate != null
                                ? AppColors.textPrimary
                                : AppColors.textMuted,
                            fontWeight: _selectedBirthDate != null
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Enclos & Mesures
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Enclos & Mensurations initiales',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    sectorsAsync.when(
                      data: (sectors) {
                        return DropdownButtonFormField<int>(
                          initialValue: _selectedSectorId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Enclos / Secteur initial',
                            prefixIcon: Icon(LucideIcons.doorOpen),
                          ),
                          items: sectors.map((s) {
                            return DropdownMenuItem<int>(
                              value: s.id,
                              child: Text(
                                '${s.name} (Cap. ${s.estimatedCapacity})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) =>
                              setState(() => _selectedSectorId = val),
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => ErrorRetryCard(
                        compact: true,
                        message: 'Impossible de charger les enclos : $e',
                        onRetry: () => ref.refresh(sectorsProvider),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _weightController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Poids actuel (kg)',
                        hintText: 'ex: 65.5',
                        suffixText: 'kg',
                        prefixIcon: Icon(LucideIcons.scale),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Prix d\'achat (FCFA)',
                        hintText: 'ex: 1500000',
                        suffixText: 'FCFA',
                        prefixIcon: Icon(LucideIcons.banknote),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Submit Button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Enregistrer l\'ovin',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
