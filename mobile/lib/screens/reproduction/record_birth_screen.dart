import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';
import '../../models/reproduction.dart';
import '../../providers/animals_provider.dart';
import '../../providers/reproduction_provider.dart';

class RecordBirthScreen extends ConsumerStatefulWidget {
  const RecordBirthScreen({super.key});

  @override
  ConsumerState<RecordBirthScreen> createState() => _RecordBirthScreenState();
}

class _RecordBirthScreenState extends ConsumerState<RecordBirthScreen> {
  Pregnancy? _selectedPregnancy;
  String? _femaleId;
  DateTime _birthDate = DateTime.now();

  int _aliveCount = 1;
  int _stillbornCount = 0;
  int _maleCount = 1;
  int _femaleCount = 0;

  final _lambIdController = TextEditingController();
  final _lambNameController = TextEditingController();
  final _lambWeightController = TextEditingController(text: '4.5');
  final _difficultiesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _lambIdController.dispose();
    _lambNameController.dispose();
    _lambWeightController.dispose();
    _difficultiesController.dispose();
    super.dispose();
  }

  void _submit() async {
    final motherId = _selectedPregnancy?.femaleId ?? _femaleId;
    if (motherId == null || motherId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner la brebis mère')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final newLambs = <Map<String, dynamic>>[];
      if (_lambIdController.text.trim().isNotEmpty && _lambNameController.text.trim().isNotEmpty) {
        newLambs.add({
          'id': _lambIdController.text.trim(),
          'name': _lambNameController.text.trim(),
          'sex': _maleCount > 0 ? 'male' : 'female',
          'weight_kg': double.tryParse(_lambWeightController.text),
        });
      }

      await ref.read(reproductionServiceProvider).recordBirth(
            pregnancyId: _selectedPregnancy?.id,
            femaleId: motherId,
            ramId: _selectedPregnancy?.ramId,
            birthDate: _birthDate,
            totalLambs: _aliveCount + _stillbornCount,
            aliveCount: _aliveCount,
            stillbornCount: _stillbornCount,
            maleCount: _maleCount,
            femaleCount: _femaleCount,
            difficulties: _difficultiesController.text.trim().isEmpty ? null : _difficultiesController.text.trim(),
            newLambs: newLambs,
          );

      ref.invalidate(pregnanciesProvider);
      ref.invalidate(animalsListProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mise bas et agneaux enregistrés avec succès')),
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
    final pregnanciesAsync = ref.watch(pregnanciesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enregistrer une Mise Bas'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Gestation en cours
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Gestation concernée', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  pregnanciesAsync.when(
                    data: (pregs) {
                      return DropdownButtonFormField<Pregnancy>(
                        value: _selectedPregnancy,
                        decoration: const InputDecoration(
                          labelText: 'Sélectionner la gestation *',
                          prefixIcon: Icon(Icons.pregnant_woman),
                        ),
                        items: pregs.map((p) {
                          return DropdownMenuItem(
                            value: p,
                            child: Text('Brebis ${p.femaleId} (Bélier : ${p.ramId ?? "Inconnu"})'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedPregnancy = val;
                            _femaleId = val?.femaleId;
                          });
                        },
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('Erreur: $e'),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Date et heure de mise bas'),
                    subtitle: Text('${_birthDate.day}/${_birthDate.month}/${_birthDate.year} ${_birthDate.hour}h${_birthDate.minute.toString().padLeft(2, '0')}'),
                    leading: const Icon(Icons.calendar_today),
                    trailing: const Icon(Icons.arrow_drop_down),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _birthDate,
                        firstDate: DateTime(2025),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => _birthDate = picked);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Agneaux nés
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Bilan de la portée', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildCounterTile('Vivants', _aliveCount, (v) => setState(() => _aliveCount = v)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildCounterTile('Mort-nés', _stillbornCount, (v) => setState(() => _stillbornCount = v)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildCounterTile('Mâles', _maleCount, (v) => setState(() => _maleCount = v)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildCounterTile('Femelles', _femaleCount, (v) => setState(() => _femaleCount = v)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _difficultiesController,
                    decoration: const InputDecoration(
                      labelText: 'Difficultés ou interventions éventuelles',
                      hintText: 'ex: Extraction manuelle, colostrum pris...',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Fiche du premier agneau
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Création automatique de l\'agneau', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _lambIdController,
                    decoration: const InputDecoration(
                      labelText: 'Identifiant du nouvel agneau',
                      hintText: 'ex: AGN-2027-01',
                      prefixIcon: Icon(Icons.badge),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _lambNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nom de l\'agneau',
                      hintText: 'ex: Petit Ladoum',
                      prefixIcon: Icon(Icons.child_care),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _lambWeightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Poids à la naissance (kg)',
                      suffixText: 'kg',
                      prefixIcon: Icon(Icons.scale),
                    ),
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
                : const Text('Enregistrer la mise bas', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterTile(String title, int count, ValueChanged<int> onChanged) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: count > 0 ? () => onChanged(count - 1) : null,
              ),
              Text('$count', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => onChanged(count + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
