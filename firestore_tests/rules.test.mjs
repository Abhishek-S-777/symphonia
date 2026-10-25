// Emulator tests for Symphonia's Firestore security rules.
//
// Run from the repository root (where firebase.json lives):
//   cd firestore_tests && npm install
//   npm test            # starts the Firestore emulator and runs these tests
//
// The emulator is started by `firebase emulators:exec` (see package.json),
// which sets FIRESTORE_EMULATOR_HOST for @firebase/rules-unit-testing.

import assert from 'node:assert';
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, test } from 'node:test';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  deleteDoc,
  doc,
  getDoc,
  setDoc,
  updateDoc,
} from 'firebase/firestore';

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'demo-symphonia',
    firestore: {
      rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8'),
      host: '127.0.0.1',
      port: 8080,
    },
  });
});

after(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

// Seed a couple (alice + bob) and an outsider (eve) with rules disabled.
async function seedCouple() {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'users/alice'), { coupleId: 'c1', email: 'a@x.com' });
    await setDoc(doc(db, 'users/bob'), { coupleId: 'c1', email: 'b@x.com' });
    await setDoc(doc(db, 'users/eve'), { coupleId: null, email: 'e@x.com' });
    await setDoc(doc(db, 'couples/c1'), { user1Id: 'alice', user2Id: 'bob' });
    await setDoc(doc(db, 'couples/c1/messages/m1'), {
      senderId: 'alice',
      content: 'hi',
    });
  });
}

test('couple member can read their couple document', async () => {
  await seedCouple();
  const db = testEnv.authenticatedContext('alice').firestore();
  await assertSucceeds(getDoc(doc(db, 'couples/c1')));
});

test('a non-member cannot read the couple document', async () => {
  await seedCouple();
  const db = testEnv.authenticatedContext('eve').firestore();
  await assertFails(getDoc(doc(db, 'couples/c1')));
});

test('a member can read and write couple messages', async () => {
  await seedCouple();
  const db = testEnv.authenticatedContext('bob').firestore();
  await assertSucceeds(getDoc(doc(db, 'couples/c1/messages/m1')));
  await assertSucceeds(
    setDoc(doc(db, 'couples/c1/messages/m2'), {
      senderId: 'bob',
      content: 'yo',
    }),
  );
});

test('a non-member cannot read couple messages', async () => {
  await seedCouple();
  const db = testEnv.authenticatedContext('eve').firestore();
  await assertFails(getDoc(doc(db, 'couples/c1/messages/m1')));
});

test('an unauthenticated client cannot read couple data', async () => {
  await seedCouple();
  const db = testEnv.unauthenticatedContext().firestore();
  await assertFails(getDoc(doc(db, 'couples/c1')));
});

test('any signed-in user can read a profile (needed for pairing)', async () => {
  await seedCouple();
  const db = testEnv.authenticatedContext('eve').firestore();
  await assertSucceeds(getDoc(doc(db, 'users/alice')));
});

test('a user can write their own profile but not overwrite anothers', async () => {
  await seedCouple();
  const db = testEnv.authenticatedContext('alice').firestore();
  await assertSucceeds(
    setDoc(doc(db, 'users/alice'), { email: 'a@x.com', coupleId: 'c1' }),
  );
  await assertFails(
    setDoc(doc(db, 'users/bob'), { email: 'hacked', coupleId: 'c1' }),
  );
});

test('pairing: a user may set ONLY coupleId on another user document', async () => {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'users/creator'), {
      email: 'c@x.com',
      coupleId: null,
    });
  });
  const db = testEnv.authenticatedContext('redeemer').firestore();
  await assertSucceeds(updateDoc(doc(db, 'users/creator'), { coupleId: 'cX' }));
  await assertFails(updateDoc(doc(db, 'users/creator'), { email: 'evil' }));
});

test('pairing codes: creator creates own, partner reads and deletes', async () => {
  const creator = testEnv.authenticatedContext('creator').firestore();
  await assertSucceeds(
    setDoc(doc(creator, 'pairingCodes/ABC123'), {
      creatorId: 'creator',
      expiresAt: new Date(),
    }),
  );
  await assertFails(
    setDoc(doc(creator, 'pairingCodes/XYZ'), { creatorId: 'someoneElse' }),
  );
  const partner = testEnv.authenticatedContext('redeemer').firestore();
  await assertSucceeds(getDoc(doc(partner, 'pairingCodes/ABC123')));
  await assertSucceeds(deleteDoc(doc(partner, 'pairingCodes/ABC123')));
});

test('a new couple must include the creator as a member', async () => {
  const db = testEnv.authenticatedContext('alice').firestore();
  await assertSucceeds(
    setDoc(doc(db, 'couples/c2'), { user1Id: 'alice', user2Id: 'bob' }),
  );
  await assertFails(
    setDoc(doc(db, 'couples/c3'), { user1Id: 'x', user2Id: 'y' }),
  );
});

test('unknown collections are denied by default', async () => {
  const db = testEnv.authenticatedContext('alice').firestore();
  await assertFails(getDoc(doc(db, 'secret_stuff/x')));
  await assertFails(setDoc(doc(db, 'secret_stuff/x'), { a: 1 }));
});
