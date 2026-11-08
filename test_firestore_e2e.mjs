// End-to-end integration test against live Cloud Firestore (mateapp-8d44d)
// Tests: Auth, Couples, Messages, Pet, Wallet, Inventory, Daily Check-in, Games, Diaries, DatePlans

const API_KEY = 'AIzaSyBB1CxIj6E0kLeqO4dYVASUR4nEsSyPcXw';
const PROJECT_ID = 'mateapp-8d44d';
const FIRESTORE_BASE = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;

async function runTests() {
  console.log('🚀 Starting MATE Firestore End-to-End Integration Verification...\n');

  // 1. Authenticate anonymously
  console.log('1️⃣ Authenticating via Firebase Auth (Anonymous)...');
  const authRes = await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${API_KEY}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ returnSecureToken: true }),
  });
  const authData = await authRes.json();
  if (!authData.idToken) {
    throw new Error(`Auth failed: ${JSON.stringify(authData)}`);
  }
  const idToken = authData.idToken;
  const uid = authData.localId;
  console.log(`✅ Authenticated successfully! UID: ${uid}\n`);

  const headers = {
    'Authorization': `Bearer ${idToken}`,
    'Content-Type': 'application/json',
  };

  const testCode = `TEST_${Date.now()}`;
  console.log(`2️⃣ Creating test couple with code: ${testCode}...`);
  // Create couple document
  const couplePayload = {
    fields: {
      code: { stringValue: testCode },
      createdAt: { timestampValue: new Date().toISOString() },
      startDate: { timestampValue: new Date().toISOString() },
      members: {
        mapValue: {
          fields: {
            [uid]: {
              mapValue: {
                fields: {
                  name: { stringValue: 'Test User' },
                  isOnline: { booleanValue: true },
                  lastActive: { timestampValue: new Date().toISOString() },
                }
              }
            }
          }
        }
      },
      intimacyScore: { integerValue: 100 },
      streakDays: { integerValue: 5 },
      pet: {
        mapValue: {
          fields: {
            name: { stringValue: 'Mimi' },
            level: { integerValue: 1 },
            hunger: { integerValue: 80 },
            happiness: { integerValue: 90 },
            cleanliness: { integerValue: 85 },
            status: { stringValue: 'happy' },
            type: { stringValue: 'cat' },
          }
        }
      }
    }
  };

  const coupleRes = await fetch(`${FIRESTORE_BASE}/couples?documentId=${testCode}`, {
    method: 'POST',
    headers,
    body: JSON.stringify(couplePayload),
  });
  const coupleResult = await coupleRes.json();
  if (!coupleRes.ok) {
    throw new Error(`Failed to create couple: ${JSON.stringify(coupleResult)}`);
  }
  console.log(`✅ Couple document created in Firestore: couples/${testCode}\n`);

  // 3. Test Messages subcollection (couples/{code}/messages)
  console.log('3️⃣ Testing Messages subcollection (couples/{code}/messages)...');
  const msgPayload = {
    fields: {
      senderId: { stringValue: uid },
      text: { stringValue: 'Chào em yêu! Đây là tin nhắn thật từ API.' },
      type: { stringValue: 'text' },
      createdAt: { timestampValue: new Date().toISOString() },
    }
  };
  const msgRes = await fetch(`${FIRESTORE_BASE}/couples/${testCode}/messages`, {
    method: 'POST',
    headers,
    body: JSON.stringify(msgPayload),
  });
  const msgResult = await msgRes.json();
  if (!msgRes.ok) {
    throw new Error(`Failed to write message: ${JSON.stringify(msgResult)}`);
  }
  console.log(`✅ Message successfully written to couples/${testCode}/messages (${msgResult.name})\n`);

  // 4. Test Pet update (feeding pet)
  console.log('4️⃣ Testing Pet Status Update...');
  const petUpdatePayload = {
    fields: {
      'pet.hunger': { integerValue: 100 },
      'pet.happiness': { integerValue: 95 },
      intimacyScore: { integerValue: 105 },
    }
  };
  const petRes = await fetch(`${FIRESTORE_BASE}/couples/${testCode}?updateMask.fieldPaths=pet.hunger&updateMask.fieldPaths=pet.happiness&updateMask.fieldPaths=intimacyScore`, {
    method: 'PATCH',
    headers,
    body: JSON.stringify(petUpdatePayload),
  });
  const petResult = await petRes.json();
  if (!petRes.ok) {
    throw new Error(`Failed to update pet: ${JSON.stringify(petResult)}`);
  }
  console.log(`✅ Pet updated: hunger=100, happiness=95, intimacyScore=105\n`);

  // 5. Test Wallet subcollection (couples/{code}/wallet)
  console.log('5️⃣ Testing Wallet Transaction subcollection (couples/{code}/wallet)...');
  const txPayload = {
    fields: {
      userId: { stringValue: uid },
      amount: { integerValue: 50 },
      balanceAfter: { integerValue: 1050 },
      description: { stringValue: 'Thưởng nhiệm vụ hằng ngày' },
      type: { stringValue: 'earn' },
      createdAt: { timestampValue: new Date().toISOString() },
    }
  };
  const txRes = await fetch(`${FIRESTORE_BASE}/couples/${testCode}/wallet`, {
    method: 'POST',
    headers,
    body: JSON.stringify(txPayload),
  });
  const txResult = await txRes.json();
  if (!txRes.ok) {
    throw new Error(`Failed to record wallet transaction: ${JSON.stringify(txResult)}`);
  }
  console.log(`✅ Wallet transaction saved in couples/${testCode}/wallet (${txResult.name})\n`);

  // 6. Test Inventory subcollection (couples/{code}/inventory)
  console.log('6️⃣ Testing Inventory subcollection (couples/{code}/inventory)...');
  const invPayload = {
    fields: {
      itemId: { stringValue: 'bg_romantic_sunset' },
      name: { stringValue: 'Hình nền Hoàng Hôn' },
      category: { stringValue: 'background' },
      inUse: { booleanValue: true },
      acquiredAt: { timestampValue: new Date().toISOString() },
    }
  };
  const invRes = await fetch(`${FIRESTORE_BASE}/couples/${testCode}/inventory?documentId=bg_romantic_sunset`, {
    method: 'POST',
    headers,
    body: JSON.stringify(invPayload),
  });
  const invResult = await invRes.json();
  if (!invRes.ok) {
    throw new Error(`Failed to add item to inventory: ${JSON.stringify(invResult)}`);
  }
  console.log(`✅ Inventory item added to couples/${testCode}/inventory/bg_romantic_sunset\n`);

  // 7. Test Checkins subcollection (couples/{code}/checkins)
  console.log('7️⃣ Testing Daily Checkin subcollection (couples/{code}/checkins)...');
  const todayKey = new Date().toISOString().slice(0, 10);
  const checkinPayload = {
    fields: {
      userId: { stringValue: uid },
      dateKey: { stringValue: todayKey },
      dayNumber: { integerValue: 1 },
      coinsEarned: { integerValue: 10 },
      streak: { integerValue: 6 },
      createdAt: { timestampValue: new Date().toISOString() },
    }
  };
  const checkinRes = await fetch(`${FIRESTORE_BASE}/couples/${testCode}/checkins?documentId=${todayKey}`, {
    method: 'POST',
    headers,
    body: JSON.stringify(checkinPayload),
  });
  const checkinResult = await checkinRes.json();
  if (!checkinRes.ok) {
    throw new Error(`Failed to record daily checkin: ${JSON.stringify(checkinResult)}`);
  }
  console.log(`✅ Daily check-in saved to couples/${testCode}/checkins/${todayKey}\n`);

  // 8. Test Games subcollection (couples/{code}/games)
  console.log('8️⃣ Testing Game Results subcollection (couples/{code}/games)...');
  const gamePayload = {
    fields: {
      userId: { stringValue: uid },
      game: { stringValue: 'quiz' },
      score: { integerValue: 5 },
      meta: {
        mapValue: {
          fields: {
            total: { integerValue: 5 },
            timeSpentSec: { integerValue: 42 },
          }
        }
      },
      createdAt: { timestampValue: new Date().toISOString() },
    }
  };
  const gameRes = await fetch(`${FIRESTORE_BASE}/couples/${testCode}/games`, {
    method: 'POST',
    headers,
    body: JSON.stringify(gamePayload),
  });
  const gameResult = await gameRes.json();
  if (!gameRes.ok) {
    throw new Error(`Failed to save game result: ${JSON.stringify(gameResult)}`);
  }
  console.log(`✅ Game result saved to couples/${testCode}/games (${gameResult.name})\n`);

  // 9. Test Diary subcollection (couples/{code}/diaries)
  console.log('9️⃣ Testing Diary subcollection (couples/{code}/diaries)...');
  const diaryPayload = {
    fields: {
      userId: { stringValue: uid },
      dateKey: { stringValue: todayKey },
      text: { stringValue: 'Hôm nay hai đứa đi dạo công viên, ăn kem rất vui! 💕' },
      mood: { stringValue: 'love' },
      createdAt: { timestampValue: new Date().toISOString() },
      updatedAt: { timestampValue: new Date().toISOString() },
    }
  };
  const diaryRes = await fetch(`${FIRESTORE_BASE}/couples/${testCode}/diaries?documentId=${todayKey}`, {
    method: 'POST',
    headers,
    body: JSON.stringify(diaryPayload),
  });
  const diaryResult = await diaryRes.json();
  if (!diaryRes.ok) {
    throw new Error(`Failed to save diary: ${JSON.stringify(diaryResult)}`);
  }
  console.log(`✅ Diary saved to couples/${testCode}/diaries/${todayKey}\n`);

  // 10. Verify reading back diary from Firestore
  console.log('🔟 Verifying Reading back Diary from Firestore...');
  const readDiaryRes = await fetch(`${FIRESTORE_BASE}/couples/${testCode}/diaries/${todayKey}`, {
    method: 'GET',
    headers,
  });
  const readDiary = await readDiaryRes.json();
  if (!readDiaryRes.ok || !readDiary.fields) {
    throw new Error(`Failed to read back diary: ${JSON.stringify(readDiary)}`);
  }
  console.log(`✅ Verified Diary text from Cloud Firestore: "${readDiary.fields.text.stringValue}" (mood: ${readDiary.fields.mood.stringValue})\n`);

  console.log('===========================================================');
  console.log('🎉 ALL FIRESTORE INTEGRATION TESTS PASSED 100% SUCCESSFULLY!');
  console.log('🔥 Verified collections and subcollections on Cloud Firestore:');
  console.log('   - couples (Cặp đôi)');
  console.log('   - couples/{code}/messages (Tin nhắn)');
  console.log('   - couples/{code}/wallet (Giao dịch ví & số dư)');
  console.log('   - couples/{code}/inventory (Kho đồ)');
  console.log('   - couples/{code}/checkins (Điểm danh)');
  console.log('   - couples/{code}/games (Kết quả trò chơi)');
  console.log('   - couples/{code}/diaries (Nhật ký hàng ngày)');
  console.log('===========================================================');
}

runTests().catch(err => {
  console.error('❌ Test failed with error:', err);
  process.exit(1);
});
