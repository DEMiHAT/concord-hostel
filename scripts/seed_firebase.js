/**
 * Firebase Seed Script for Concord Hostel Management System
 * 
 * This script populates Firestore with test data AND creates Auth users.
 * 
 * SETUP:
 *   1. Go to: https://console.firebase.google.com/project/concord-hostel/settings/serviceaccounts/adminsdk
 *   2. Click "Generate new private key" → Download the JSON file
 *   3. Save it as: scripts/serviceAccountKey.json 
 *   4. Run: node scripts/seed_firebase.js
 * 
 * All test users use password: concord123
 */

const { initializeApp, cert } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');
const path = require('path');
const fs = require('fs');

// ── Check for service account key ──
const serviceAccountPath = path.join(__dirname, 'serviceAccountKey.json');
if (!fs.existsSync(serviceAccountPath)) {
  console.log('╔══════════════════════════════════════════════════════════╗');
  console.log('║  ❌ Missing: scripts/serviceAccountKey.json              ║');
  console.log('╠══════════════════════════════════════════════════════════╣');
  console.log('║  To get it:                                              ║');
  console.log('║  1. Open this URL in your browser:                       ║');
  console.log('║     https://console.firebase.google.com/project/         ║');
  console.log('║     concord-hostel/settings/serviceaccounts/adminsdk     ║');
  console.log('║  2. Click "Generate new private key"                     ║');
  console.log('║  3. Save the downloaded file as:                         ║');
  console.log('║     scripts/serviceAccountKey.json                       ║');
  console.log('║  4. Run this script again                                ║');
  console.log('╚══════════════════════════════════════════════════════════╝');
  process.exit(1);
}

const serviceAccount = require(serviceAccountPath);
initializeApp({
  credential: cert(serviceAccount),
  projectId: 'concord-hostel',
});

const auth = getAuth();
const db = getFirestore();

const DEFAULT_PASSWORD = 'concord123';

// ═══════════════════════════════════════════════════════════
// TEST USERS
// ═══════════════════════════════════════════════════════════

const users = [
  {
    email: 'arjun@university.edu',
    displayName: 'Arjun Mehta',
    firestoreData: {
      name: 'Arjun Mehta',
      email: 'arjun@university.edu',
      role: 'student',
      rollNumber: 'CS21B1045',
      hostelBlock: 'Block A',
      roomNumber: 'A-204',
      department: 'Computer Science',
      phone: '+91 98765 43210',
      parentPhone: '+91 98765 43211',
    },
  },
  {
    email: 'neha@university.edu',
    displayName: 'Neha Kumar',
    firestoreData: {
      name: 'Neha Kumar',
      email: 'neha@university.edu',
      role: 'student',
      rollNumber: 'CS21B1046',
      hostelBlock: 'Block A',
      roomNumber: 'A-210',
      department: 'Computer Science',
      phone: '+91 98765 43212',
      parentPhone: '+91 98765 43213',
    },
  },
  {
    email: 'rahul@university.edu',
    displayName: 'Rahul Verma',
    firestoreData: {
      name: 'Rahul Verma',
      email: 'rahul@university.edu',
      role: 'student',
      rollNumber: 'CS21B1047',
      hostelBlock: 'Block A',
      roomNumber: 'A-305',
      department: 'Computer Science',
      phone: '+91 98765 43214',
      parentPhone: '+91 98765 43215',
    },
  },
  {
    email: 'priyap@university.edu',
    displayName: 'Priya Patel',
    firestoreData: {
      name: 'Priya Patel',
      email: 'priyap@university.edu',
      role: 'student',
      rollNumber: 'EC21B1012',
      hostelBlock: 'Block A',
      roomNumber: 'A-108',
      department: 'Electronics',
      phone: '+91 98765 43216',
      parentPhone: '+91 98765 43217',
    },
  },
  {
    email: 'aditya@university.edu',
    displayName: 'Aditya Singh',
    firestoreData: {
      name: 'Aditya Singh',
      email: 'aditya@university.edu',
      role: 'student',
      rollNumber: 'ME21B1005',
      hostelBlock: 'Block A',
      roomNumber: 'A-412',
      department: 'Mechanical',
      phone: '+91 98765 43218',
      parentPhone: '+91 98765 43219',
    },
  },
  {
    email: 'kavya@university.edu',
    displayName: 'Kavya Sharma',
    firestoreData: {
      name: 'Kavya Sharma',
      email: 'kavya@university.edu',
      role: 'student',
      rollNumber: 'CS21B1048',
      hostelBlock: 'Block A',
      roomNumber: 'A-202',
      department: 'Computer Science',
      phone: '+91 98765 43220',
      parentPhone: '+91 98765 43221',
    },
  },
  {
    email: 'priya.rt@university.edu',
    displayName: 'Dr. Priya Sharma',
    firestoreData: {
      name: 'Dr. Priya Sharma',
      email: 'priya.rt@university.edu',
      role: 'rt',
      hostelBlock: 'Block A',
      department: 'Computer Science',
    },
  },
  {
    email: 'rajesh.mehta@gmail.com',
    displayName: 'Rajesh Mehta',
    firestoreData: {
      name: 'Rajesh Mehta',
      email: 'rajesh.mehta@gmail.com',
      role: 'parent',
      phone: '+91 98765 43211',
    },
  },
  {
    email: 'vikram.hod@university.edu',
    displayName: 'Prof. Vikram Singh',
    firestoreData: {
      name: 'Prof. Vikram Singh',
      email: 'vikram.hod@university.edu',
      role: 'hod',
      department: 'Computer Science',
    },
  },
  {
    email: 'suresh.warden@university.edu',
    displayName: 'Mr. Suresh Kumar',
    firestoreData: {
      name: 'Mr. Suresh Kumar',
      email: 'suresh.warden@university.edu',
      role: 'warden',
      hostelBlock: 'Block A',
    },
  },
  {
    email: 'anita.faculty@university.edu',
    displayName: 'Dr. Anita Patel',
    firestoreData: {
      name: 'Dr. Anita Patel',
      email: 'anita.faculty@university.edu',
      role: 'faculty',
      department: 'Computer Science',
    },
  },
  {
    email: 'ram.security@university.edu',
    displayName: 'Ram Singh',
    firestoreData: {
      name: 'Ram Singh',
      email: 'ram.security@university.edu',
      role: 'security',
    },
  },
  {
    email: 'admin@university.edu',
    displayName: 'System Admin',
    firestoreData: {
      name: 'System Admin',
      email: 'admin@university.edu',
      role: 'admin',
    },
  },
  {
    email: 'kavitha.medical@university.edu',
    displayName: 'Dr. Kavitha Nair',
    firestoreData: {
      name: 'Dr. Kavitha Nair',
      email: 'kavitha.medical@university.edu',
      role: 'medical_officer',
      department: 'Health Services',
    },
  },
];

// ═══════════════════════════════════════════════════════════
// SEED FUNCTIONS
// ═══════════════════════════════════════════════════════════

async function createAuthUser(userData) {
  try {
    try {
      const existing = await auth.getUserByEmail(userData.email);
      console.log(`  ⚡ Already exists: ${userData.email} → ${existing.uid}`);
      return existing.uid;
    } catch (e) { /* doesn't exist yet */ }

    const userRecord = await auth.createUser({
      email: userData.email,
      password: DEFAULT_PASSWORD,
      displayName: userData.displayName,
      emailVerified: true,
    });
    console.log(`  ✅ Created: ${userData.email} → ${userRecord.uid}`);
    return userRecord.uid;
  } catch (error) {
    console.error(`  ❌ Failed ${userData.email}:`, error.message);
    return null;
  }
}

async function seedUsers() {
  console.log('\n🔐 Creating Auth users & Firestore documents...\n');
  const uidMap = {};

  for (const user of users) {
    const uid = await createAuthUser(user);
    if (uid) {
      uidMap[user.email] = uid;
      await db.collection('users').doc(uid).set({
        ...user.firestoreData,
        createdAt: Timestamp.now(),
      });
      console.log(`  📄 Doc: ${user.firestoreData.name} [${user.firestoreData.role}]`);
    }
  }
  return uidMap;
}

async function seedLeaveRequests(uidMap) {
  console.log('\n📋 Creating leave requests...\n');

  const now = Date.now();
  const DAY = 86400000;
  const HOUR = 3600000;
  const MIN = 60000;
  const s = uidMap['arjun@university.edu'];
  const r = uidMap['priya.rt@university.edu'];
  const p = uidMap['rajesh.mehta@gmail.com'];

  if (!s) { console.log('  ⚠️ Skipping — student not found'); return; }

  const requests = [
    {
      id: 'lr1', studentId: s, studentName: 'Arjun Mehta', studentRollNumber: 'CS21B1045',
      hostelBlock: 'Block A', roomNumber: 'A-204', leaveType: 'dayPass', status: 'approved',
      reason: 'Medical appointment at city hospital',
      fromDate: Timestamp.fromMillis(now - DAY), toDate: Timestamp.fromMillis(now - DAY),
      createdAt: Timestamp.fromMillis(now - 2*DAY), updatedAt: Timestamp.fromMillis(now - DAY),
      qrPassId: 'qr1', rejectionReason: null, proofDocumentUrls: [],
      approvalHistory: [{
        approverId: r, approverName: 'Dr. Priya Sharma', approverRole: 'RT',
        action: 'approved', comment: 'Valid medical reason',
        timestamp: Timestamp.fromMillis(now - DAY - 20*HOUR),
      }],
    },
    {
      id: 'lr2', studentId: s, studentName: 'Arjun Mehta', studentRollNumber: 'CS21B1045',
      hostelBlock: 'Block A', roomNumber: 'A-204', leaveType: 'weekend', status: 'forwarded_to_parent',
      reason: 'Family gathering at home',
      fromDate: Timestamp.fromMillis(now + 3*DAY), toDate: Timestamp.fromMillis(now + 5*DAY),
      createdAt: Timestamp.fromMillis(now - 6*HOUR), updatedAt: Timestamp.fromMillis(now - 3*HOUR),
      qrPassId: null, rejectionReason: null, proofDocumentUrls: [],
      approvalHistory: [{
        approverId: r, approverName: 'Dr. Priya Sharma', approverRole: 'RT',
        action: 'forwarded', comment: 'Forwarded to parent for approval',
        timestamp: Timestamp.fromMillis(now - 3*HOUR),
      }],
    },
    {
      id: 'lr3', studentId: s, studentName: 'Arjun Mehta', studentRollNumber: 'CS21B1045',
      hostelBlock: 'Block A', roomNumber: 'A-204', leaveType: 'emergency', status: 'pending',
      reason: 'Urgent family emergency - grandmother hospitalized',
      fromDate: Timestamp.fromMillis(now), toDate: Timestamp.fromMillis(now + 2*DAY),
      createdAt: Timestamp.fromMillis(now - 30*MIN), updatedAt: Timestamp.fromMillis(now - 30*MIN),
      qrPassId: null, rejectionReason: null, proofDocumentUrls: [], approvalHistory: [],
    },
    {
      id: 'lr4', studentId: s, studentName: 'Arjun Mehta', studentRollNumber: 'CS21B1045',
      hostelBlock: 'Block A', roomNumber: 'A-204', leaveType: 'academic', status: 'rejected',
      reason: 'Conference attendance in Bangalore',
      fromDate: Timestamp.fromMillis(now - 10*DAY), toDate: Timestamp.fromMillis(now - 8*DAY),
      createdAt: Timestamp.fromMillis(now - 12*DAY), updatedAt: Timestamp.fromMillis(now - 11*DAY),
      qrPassId: null, rejectionReason: 'Insufficient academic justification', proofDocumentUrls: [],
      approvalHistory: [{
        approverId: r, approverName: 'Dr. Priya Sharma', approverRole: 'RT',
        action: 'rejected', comment: 'Insufficient academic justification',
        timestamp: Timestamp.fromMillis(now - 11*DAY),
      }],
    },
    {
      id: 'lr5', studentId: s, studentName: 'Arjun Mehta', studentRollNumber: 'CS21B1045',
      hostelBlock: 'Block A', roomNumber: 'A-204', leaveType: 'overnight', status: 'approved',
      reason: "Visiting family for mother's birthday",
      fromDate: Timestamp.fromMillis(now + DAY), toDate: Timestamp.fromMillis(now + 2*DAY),
      createdAt: Timestamp.fromMillis(now - 3*DAY), updatedAt: Timestamp.fromMillis(now - 2*DAY),
      qrPassId: 'qr2', rejectionReason: null, proofDocumentUrls: [],
      approvalHistory: [
        { approverId: r, approverName: 'Dr. Priya Sharma', approverRole: 'RT',
          action: 'approved', comment: null, timestamp: Timestamp.fromMillis(now - 2.5*DAY) },
        { approverId: p, approverName: 'Rajesh Mehta', approverRole: 'Parent',
          action: 'approved', comment: null, timestamp: Timestamp.fromMillis(now - 2*DAY) },
      ],
    },
  ];

  for (const { id, ...data } of requests) {
    await db.collection('leave_requests').doc(id).set(data);
    console.log(`  ✅ ${id} [${data.leaveType}] → ${data.status}`);
  }
}

async function seedQrPasses(uidMap) {
  console.log('\n🎟️  Creating QR passes...\n');

  const now = Date.now();
  const DAY = 86400000;
  const HOUR = 3600000;
  const s = uidMap['arjun@university.edu'];
  const sec = uidMap['ram.security@university.edu'];

  if (!s) { console.log('  ⚠️ Skipping — student not found'); return; }

  const passes = [
    {
      id: 'qr1', leaveRequestId: 'lr1', studentId: s,
      studentName: 'Arjun Mehta', studentRollNumber: 'CS21B1045',
      state: 'hostel_entered',
      validFrom: Timestamp.fromMillis(now - DAY - 8*HOUR),
      validUntil: Timestamp.fromMillis(now - DAY + 20*HOUR),
      gateLogs: [
        { gateType: 'hostel', action: 'exit', securityId: sec, laneType: 'scanLane',
          timestamp: Timestamp.fromMillis(now - DAY - 6*HOUR) },
        { gateType: 'main', action: 'exit', securityId: sec, laneType: null,
          timestamp: Timestamp.fromMillis(now - DAY - 5.8*HOUR) },
        { gateType: 'main', action: 'entry', securityId: sec, laneType: null,
          timestamp: Timestamp.fromMillis(now - 18*HOUR) },
        { gateType: 'hostel', action: 'entry', securityId: sec, laneType: 'scanLane',
          timestamp: Timestamp.fromMillis(now - 17.8*HOUR) },
      ],
    },
    {
      id: 'qr2', leaveRequestId: 'lr5', studentId: s,
      studentName: 'Arjun Mehta', studentRollNumber: 'CS21B1045',
      state: 'unused',
      validFrom: Timestamp.fromMillis(now + DAY),
      validUntil: Timestamp.fromMillis(now + 2*DAY + 20*HOUR),
      gateLogs: [],
    },
  ];

  for (const { id, ...data } of passes) {
    await db.collection('qr_passes').doc(id).set(data);
    console.log(`  ✅ ${id} [${data.state}]`);
  }
}

// ═══════════════════════════════════════════════════════════
async function main() {
  console.log('╔══════════════════════════════════════════════════╗');
  console.log('║   🔥 Concord Firebase Seed Script               ║');
  console.log('║   Project: concord-hostel                        ║');
  console.log('╚══════════════════════════════════════════════════╝');
  console.log(`\n🔑 All users password: "${DEFAULT_PASSWORD}"\n`);

  try {
    const uidMap = await seedUsers();
    await seedLeaveRequests(uidMap);
    await seedQrPasses(uidMap);

    console.log('\n╔══════════════════════════════════════════════════╗');
    console.log('║   ✅ Seeding complete!                           ║');
    console.log('╚══════════════════════════════════════════════════╝');
    console.log('\n📋 Login credentials (password: concord123):');
    console.log('─────────────────────────────────────────────────');
    for (const u of users) {
      console.log(`  ${u.firestoreData.role.padEnd(16)} │ ${u.email}`);
    }
    console.log('─────────────────────────────────────────────────');
    console.log('\n💡 Set isDemo = false in main.dart to switch to Firebase\n');
  } catch (error) {
    console.error('\n❌ Error:', error.message);
  }
  process.exit(0);
}

main();
