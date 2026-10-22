import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/formatters.dart';
import '../../providers/animals_provider.dart';
import '../../providers/reproduction_provider.dart';

class AddMatingScreen extends ConsumerStatefulWidget {
  const AddMatingScreen({super.key});

  @override
  ConsumerState<AddMatingScreen> createState() => _AddMatingScreenState();
}

class _AddMatingScreenState extends ConsumerState<AddMatingScreen> {
  String? _selectedFemaleId;
  String? _selectedRamId;
  DateTime _matingDate = DateTime.now();
  String _matingType = 'natural';
  bool _startPregnancyTracking = true;
  bool _isSubmitting = false;

  void _submit() async {
    if (_selectedFemaleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner la brebis')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final reproService = ref.read(reproductionServiceProvider);

      // 1. Record mating
      final mating = await reproService.recordMating(
        femaleId: _selectedFemaleId!,
        ramId: _selectedRamId,
        matingDate: _matingDate,
        matingType: _matingType,
      );

      // 2. Optionally start pregnancy tracking automatically
      if (_startPregnancyTracking) {
        await reproService.createPregnancy(
          femaleId: _selectedFemaleId!,
          ramId: _selectedRamId,
          matingEventId: mating.id,
          startDate: _matingDate,
          gestationDurationDays: 150,
          confirmationStatus: 'confirmed',
        );
      }

      ref.invalidate(matingsProvider);
      ref.invalidate(pregnanciesProvider);
      ref.invalidate(animalsListProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saillie et suivi de gestation enregistrés')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final animalsAsync = ref.watch(animalsListProvider);
    final calculatedExpectedBirth = _matingDate.add(const Duration(days: 150));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Déclarer une Saillie'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Reproducteurs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  // Female dropdown
                  animalsAsync.when(
                    data: (animals) {
                      final females = animals.where((a) => a.isFemale).toList();
                      return DropdownButtonFormField<String>(
                        value: _selectedFemaleId,
                        decoration: const InputDecoration(
                          labelText: 'Brebis (Femelle) *',
                          prefixIcon: Icon(Icons.female, color: Colors.pink),
                        ),
                        items: females.map((f) {
                          return DropdownMenuItem(
                            value: f.id,
                            child: Text('${f.name} (${f.id} - ${f.breed?.name ?? ""})'),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedFemaleId = val),
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('Erreur: $e'),
                  ),
                  const SizedBox(height: 12),

                  // Ram dropdown
                  animalsAsync.when(
                    data: (animals) {
                      final males = animals.where((a) => a.isMale).toList();
                      return DropdownButtonFormField<String>(
                        value: _selectedRamId,
                        decoration: const InputDecoration(
                          labelText: 'Bélier (Reproducteur)',
                          prefixIcon: Icon(Icons.male, color: Colors.blueAccent),
                        ),
                        items: males.map((m) {
                          return DropdownMenuItem(
                            value: m.id,
                            child: Text('${m.name} (${m.id} - ${m.breed?.name ?? ""})'),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedRamId = val),
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('Erreur: $e'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Date & Type
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Date & Conditions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Date de la saillie'),
                    subtitle: Text(Formatters.formatDate(_matingDate)),
                    leading: const Icon(Icons.calendar_today),
                    trailing: const Icon(Icons.arrow_drop_down),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _matingDate,
                        firstDate: DateTime(2025),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (picked != null) {
                        setState(() => _matingDate = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _matingType,
                    decoration: const InputDecoration(labelText: 'Type d\'accouplement'),
                    items: const [
                      DropdownMenuItem(value: 'natural', child: Text('Saillie naturelle en enclos')),
                      DropdownMenuItem(value: 'assisted', child: Text('Saillie assistée / insémination')),
                    ],
                    onChanged: (val) => setState(() => _matingType = val ?? 'natural'),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Activer le suivi de gestation (150 jours)'),
                    subtitle: Text('Date prévisionnelle estimée : ${Formatters.formatDate(calculatedExpectedBirth)}'),
                    value: _startPregnancyTracking,
                    onChanged: (val) => setState(() => _startPregnancyTracking = val),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isSubmitting
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Valider la saillie', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
