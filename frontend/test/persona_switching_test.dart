import 'package:flutter_test/flutter_test.dart';
import 'package:mausam/state/mausam_state.dart';

void main() {
  group('MAUSAM 7 Personas Verification', () {
    late MausamState state;

    setUp(() {
      state = MausamState();
    });

    test('All 7 personas are available with tailored domains and parameters', () {
      expect(state.personas.length, 7);

      final expectedPersonas = [
        'rmc',
        'health',
        'fitness',
        'beach',
        'traveler',
        'family',
        'agriculture',
      ];

      for (final id in expectedPersonas) {
        final match = state.personas.where((p) => p.id == id);
        expect(match.isNotEmpty, isTrue, reason: 'Persona $id should exist');
      }
    });

    test('Switching persona updates currentPersona and state properly', () {
      // 1. Health-Conscious
      state.setPersona('health');
      expect(state.selectedPersonaId, 'health');
      expect(state.currentPersona.name, contains('Health'));

      // 2. Outdoor Fitness
      state.setPersona('fitness');
      expect(state.selectedPersonaId, 'fitness');
      expect(state.currentPersona.name, contains('Fitness'));

      // 3. Beachgoers & Surfers
      state.setPersona('beach');
      expect(state.selectedPersonaId, 'beach');
      expect(state.currentPersona.name, contains('Beach'));

      // 4. Travelers & Commuters
      state.setPersona('traveler');
      expect(state.selectedPersonaId, 'traveler');
      expect(state.currentPersona.name, contains('Travel'));

      // 5. Parents & Families
      state.setPersona('family');
      expect(state.selectedPersonaId, 'family');
      expect(state.currentPersona.name, contains('Parents'));

      // 6. Agriculture & Gardeners
      state.setPersona('agriculture');
      expect(state.selectedPersonaId, 'agriculture');
      expect(state.currentPersona.name, contains('Agriculture'));

      // 7. RMC Logistics Manager (Primary)
      state.setPersona('rmc');
      expect(state.selectedPersonaId, 'rmc');
      expect(state.currentPersona.name, contains('RMC'));
    });
  });
}
