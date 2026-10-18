import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/controller/users/update_data.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late UpdateDataController updateDataController;

  setUp(() {
    locator.reset();
    locator.allowReassignment = true;

    fakeFirestore = FakeFirebaseFirestore();

    updateDataController = UpdateDataController(db: fakeFirestore);

    locator.registerSingleton<FirebaseFirestore>(fakeFirestore);
    locator.registerSingleton<UpdateDataController>(updateDataController);
  });

  tearDown(() {
    locator.reset();
  });

  group('UpdateDataController |', () {
    const userId = 'student-123';

    test(
      'updateHealthProfile deve salvar os dados e fazer merge com o perfil existente',
      () async {
        await fakeFirestore.collection('users').doc(userId).set({
          'name': 'Grazi',
          'registrationProfile': {
            'measurements': {'age': 28, 'heightCm': 165},
          },
        });

        await updateDataController.updateHealthProfile(
          userId: userId,
          conditions: ['Joelho', 'Hipertensão'],
          restrictions: ['Asma/Bronquite'],
          notes: 'Cuidado com impacto',
        );

        final snapshot =
            await fakeFirestore.collection('users').doc(userId).get();
        final data = snapshot.data()!;

        final health = data['registrationProfile']['health'];
        expect(health['conditions'], ['Joelho', 'Hipertensão']);
        expect(health['restrictions'], ['Asma/Bronquite']);
        expect(health['notes'], 'Cuidado com impacto');

        final measurements = data['registrationProfile']['measurements'];
        expect(measurements['age'], 28);
        expect(data['name'], 'Grazi');
      },
    );

    test(
      'updateEmergencyContact deve salvar o contato e fazer merge com o perfil existente',
      () async {
        await fakeFirestore.collection('users').doc(userId).set({
          'name': 'Grazi',
          'registrationProfile': {'primaryGoal': 'conditioning'},
        });

        await updateDataController.updateEmergencyContact(
          userId: userId,
          name: 'Carlos',
          phone: '11999999999',
          relationship: 'partner',
        );

        final snapshot =
            await fakeFirestore.collection('users').doc(userId).get();
        final data = snapshot.data()!;

        final contact = data['registrationProfile']['emergencyContact'];
        expect(contact['name'], 'Carlos');
        expect(contact['phone'], '11999999999');
        expect(contact['relationship'], 'partner');

        expect(data['registrationProfile']['primaryGoal'], 'conditioning');
      },
    );

    test(
      'updateHealthProfile deve criar o registrationProfile caso ele não exista no Firebase',
      () async {
        await fakeFirestore.collection('users').doc(userId).set({
          'name': 'Grazi',
          'email': 'grazi@example.com',
        });

        await updateDataController.updateHealthProfile(
          userId: userId,
          conditions: ['Nenhuma dor'],
          restrictions: ['Não possuo'],
          notes: '',
        );

        final snapshot =
            await fakeFirestore.collection('users').doc(userId).get();
        final data = snapshot.data()!;

        expect(data['registrationProfile']['health']['conditions'], [
          'Nenhuma dor',
        ]);
        expect(data['registrationProfile']['health']['restrictions'], [
          'Não possuo',
        ]);
        expect(data['email'], 'grazi@example.com');
      },
    );
  });
}
