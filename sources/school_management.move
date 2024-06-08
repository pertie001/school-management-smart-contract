#[allow(unused_variable)]
module school_management::management {
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{TxContext, sender};
    use sui::clock::{Clock, timestamp_ms};
    use sui::balance::{Self, Balance};
    use sui::sui::{SUI};
    use sui::coin::{Self, Coin};
    use sui::table::{Self, Table};
    use std::string::{String};
    use std::option::{Option, some};

    const MALE: u8 = 0;
    const FEMALE: u8 = 1;

    const ERROR_INVALID_GENDER: u64 = 0;
    const ERROR_INVALID_ACCESS: u64 = 1;
    const ERROR_INSUFFICIENT_FUNDS: u64 = 2;
    const ERROR_INVALID_TIME: u64 = 3;
    const ERROR_NOT_FOUND: u64 = 4;

    // School Structure
    struct School has key, store {
        id: UID,
        name: String,
        location: String,
        contact_info: String,
        school_type: String,
        fees: Table<ID, Fee>, // Changed the key type to ID for unique student identifiers
        balance: Balance<SUI>,
        subjects: Table<ID, Subject>,
        lecturers: Table<ID, Lecturer>,
        owner: address, // Added owner field for authorization checks
    }

    struct SchoolCap has key, store {
        id: UID,
        school: ID,
    }

    // Student Structure
    struct Student has key, store {
        id: UID,
        school: ID,
        name: String,
        age: u64,
        gender: u8,
        contact_info: String,
        guardian_contact: String,
        enrollment_date: u64,
        pay: bool, // Initialize pay based on fee payment during enrollment
    }

    // Subject Structure
    struct Subject has key, store {
        id: UID,
        school: ID,
        name: String,
        lecturer: Option<ID>, // Changed lecturer type to ID for better management
    }

    // Lecturer Structure
    struct Lecturer has key, store {
        id: UID,
        school: ID,
        name: String,
        contact_info: String,
    }

    // Fee Structure
    struct Fee has copy, store, drop {
        student_id: ID,
        amount: u64,
        payment_date: u64,
        paid: bool, // Added paid field to keep track of paid fees
    }

    // Create a new school
    public fun create_school(name: String, location: String, contact_info: String, school_type: String, ctx: &mut TxContext): (School, SchoolCap) {
        let id_ = object::new(ctx);
        let inner_ = object::uid_to_inner(&id_);
        let school = School {
            id: id_,
            name,
            location,
            contact_info,
            school_type,
            fees: table::new(ctx),
            balance: balance::zero(),
            subjects: table::new(ctx),
            lecturers: table::new(ctx),
            owner: sender(ctx), // Set the creator as the owner
        };
        let cap = SchoolCap {
            id: object::new(ctx),
            school: inner_,
        };
        (school, cap)
    }

    // Enroll a student
    public fun enroll_student(school: &mut School, name: String, age: u64, gender: u8, contact_info: String, guardian_contact: String, enrollment_date: u64, ctx: &mut TxContext): Student {
        assert!(gender == MALE || gender == FEMALE, ERROR_INVALID_GENDER);
        let student_id = object::new(ctx);
        let pay = false; // Initialize pay to false
        Student {
            id: student_id,
            school: object::id(school),
            name,
            age,
            gender,
            contact_info,
            guardian_contact,
            enrollment_date,
            pay,
        }
    }

    // Generate a fee for a student
    public fun generate_fee(school: &mut School, student_id: ID, amount: u64, due_date: u64, c: &Clock, ctx: &mut TxContext) {
        let fee = Fee {
            student_id,
            amount,
            payment_date: timestamp_ms(c) + due_date,
            paid: false, // Initialize paid to false
        };
        table::add(&mut school.fees, student_id, fee);
    }

    // Pay a fee
    public fun pay_fee(school: &mut School, student_id: ID, coin: Coin<SUI>, c: &Clock, ctx: &mut TxContext) {
        let fee = table::borrow_mut(&mut school.fees, student_id);
        assert!(coin::value(&coin) == fee.amount, ERROR_INSUFFICIENT_FUNDS);
        assert!(fee.payment_date >= timestamp_ms(c), ERROR_INVALID_TIME);
        // Join the balance
        let balance_ = coin::into_balance(coin);
        balance::join(&mut school.balance, balance_);
        // Mark fee as paid
        fee.paid = true;
    }

    // Withdraw funds from the school balance
    public fun withdraw(school: &mut School, ctx: &mut TxContext): Coin<SUI> {
        assert!(sender(ctx) == school.owner, ERROR_INVALID_ACCESS); // Check if the caller is the owner
        let balance_ = balance::withdraw_all(&mut school.balance);
        let coin_ = coin::from_balance(balance_, ctx);
        coin_
    }

    // Add a subject
    public fun add_subject(school: &mut School, name: String, lecturer: Option<ID>, ctx: &mut TxContext): Subject {
        let subject_id = object::new(ctx);
        Subject {
            id: subject_id,
            school: object::id(school),
            name,
            lecturer,
        }
    }

    // Assign a lecturer to a subject
    public fun assign_lecturer_to_subject(subject: &mut Subject, lecturer: ID, ctx: &mut TxContext) {
        subject.lecturer = some(lecturer);
    }

    // Add a lecturer
    public fun add_lecturer(school: &mut School, name: String, contact_info: String, ctx: &mut TxContext): Lecturer {
        let lecturer_id = object::new(ctx);
        Lecturer {
            id: lecturer_id,
            school: object::id(school),
            name,
            contact_info,
        }
    }

    // =================== Public view functions ===================
    public fun get_school_balance(school: &School): u64 {
        balance::value(&school.balance)
    }

    public fun get_student_status(school: &School, student_id: ID): bool {
        let fee = table::borrow(&school.fees, student_id);
        fee.paid
    }

    public fun get_fee_amount(school: &School, student_id: ID): u64 {
        let fee = table::borrow(&school.fees, student_id);
        fee.amount
    }

    // =================== CRUD Operations ===================

    // Update student information
    public fun update_student_info(student: &mut Student, name: String, age: u64, gender: u8, contact_info: String, guardian_contact: String, ctx: &mut TxContext) {
        assert!(gender == MALE || gender == FEMALE, ERROR_INVALID_GENDER);
        assert!(!name.is_empty(), ERROR_INVALID_GENDER); // Added validation for empty name
        student.name = name;
        student.age = age;
        student.gender = gender;
        student.contact_info = contact_info;
        student.guardian_contact = guardian_contact;
    }

    // Remove student
    public fun remove_student(school: &mut School, student_id: ID, ctx: &mut TxContext) {
        table::remove(&mut school.fees, student_id);
    }

    // Add more funds to the school balance
    public fun add_funds_to_school(school: &mut School, amount: Coin<SUI>, ctx: &mut TxContext) {
    let added_balance = coin::into_balance(amount);
    balance::join(&mut school.balance, added_balance);
}

// Refund funds from the school balance
public fun refund_funds_from_school(school: &mut School, amount: u64, ctx: &mut TxContext): Coin<SUI> {
    let balance_value = balance::value(&school.balance);
    assert!(balance_value >= amount, ERROR_INSUFFICIENT_FUNDS);
    let coin_ = coin::take(&mut school.balance, amount, ctx);
    coin_
}

// Update subject information
public fun update_subject_info(subject: &mut Subject, name: String, lecturer: Option<ID>, ctx: &mut TxContext) {
    assert!(!name.is_empty(), ERROR_INVALID_GENDER); // Added validation for empty name
    subject.name = name;
    subject.lecturer = lecturer;
}

// Update lecturer information
public fun update_lecturer_info(lecturer: &mut Lecturer, name: String, contact_info: String, ctx: &mut TxContext) {
    assert!(!name.is_empty(), ERROR_INVALID_GENDER); // Added validation for empty name
    lecturer.name = name;
    lecturer.contact_info = contact_info;
}

// Get details of a specific student
public fun get_student_details(student: &Student): (String, u64, u8, String, String, u64, bool) {
    (student.name, student.age, student.gender, student.contact_info, student.guardian_contact, student.enrollment_date, student.pay)
}

// Get details of a specific lecturer
public fun get_lecturer_details(lecturer: &Lecturer): (String, String) {
    (lecturer.name, lecturer.contact_info)
}

// Get details of a specific subject
public fun get_subject_details(subject: &Subject): (String, Option<ID>) {
    (subject.name, subject.lecturer)
}

// Get all students in a school
public fun get_all_students(school: &School): vector<Student> {
    let students = vector::empty<Student>();
    let fees = table::borrow(&school.fees);
    table::for_each(&fees, |_, fee| {
        let student = table::borrow(&school.students, fee.student_id);
        vector::push_back(&mut students, *student);
    });
    students
}

// Get all lecturers in a school
public fun get_all_lecturers(school: &School): vector<Lecturer> {
    let lecturers = vector::empty<Lecturer>();
    let lecturers_table = table::borrow(&school.lecturers);
    table::for_each(&lecturers_table, |_, lecturer| {
        vector::push_back(&mut lecturers, *lecturer);
    });
    lecturers
}

// Get all subjects in a school
public fun get_all_subjects(school: &School): vector<Subject> {
    let subjects = vector::empty<Subject>();
    let subjects_table = table::borrow(&school.subjects);
    table::for_each(&subjects_table, |_, subject| {
        vector::push_back(&mut subjects, *subject);
    });
    subjects
}
}
