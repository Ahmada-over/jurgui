import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';
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
  final _weightController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();

  int? _selectedBreedId;
  int? _selectedSectorId;
  String _selectedSex = 'female';
  String _selectedOrigin = 'purchase';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _tagController.dispose();
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
        'breed_id': _selectedBreedId,
        'sex': _selectedSex,
        'origin': _selectedOrigin,
        'current_sector_id': _selectedSectorId,
        'current_weight_kg': double.tryParse(_weightController.text),
        'purchase_price_cfa': double.tryParse(_priceController.text),
        'body_condition': 'normal',
        'status': 'active',
        'notes': _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      };

      await ref.read(animalActionsServiceProvider).createAnimal(payload);
      ref.invalidate(animalsListProvider);

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
                          value: _selectedBreedId,
                          decoration: const InputDecoration(
                            labelText: 'Race ovine *',
                            prefixIcon: Icon(LucideIcons.folders),
                          ),
                          items: breeds.map((b) {
                            return DropdownMenuItem<int>(
                              value: b.id,
                              child: Text(b.name),
                            );
                          }).toList(),
                          onChanged: (val) =>
                              setState(() => _selectedBreedId = val),
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text('Erreur: $e'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedSex,
                      decoration: const InputDecoration(
                        labelText: 'Sexe *',
                        prefixIcon: Icon(LucideIcons.venusAndMars),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'female',
                          child: Text('Femelle (Brebis)'),
                        ),
                        DropdownMenuItem(
                          value: 'male',
                          child: Text('Mâle (Bélier)'),
                        ),
                      ],
                      onChanged: (val) =>
                          setState(() => _selectedSex = val ?? 'female'),
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
                          value: _selectedSectorId,
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
                      error: (e, _) => Text('Erreur: $e'),
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
