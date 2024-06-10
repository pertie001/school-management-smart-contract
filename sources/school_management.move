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

    struct School has key, store {
        id: UID,
        name: String,
        location: String,
        contact_info: String,
        school_type: String,
        fees: Table<address, Fee>,
        balance: Balance<SUI>,
        subjects: Table<address, Subject>,
        lecturers: Table<address, Lecturer>,
    }

    struct SchoolCap has key, store {
        id: UID,
        school: ID,
    }

    struct Student has key, store {
        id: UID,
        school: ID,
        name: String,
        age: u64,
        gender: u8,
        contact_info: String,
        guardian_contact: String,
        enrollment_date: u64,
        pay: bool
    }

    struct Subject has key, store {
        id: UID,
        school: ID,
        name: String,
        lecturer: Option<address>,
    }

    struct Lecturer has key, store {
        id: UID,
        school: ID,
        name: String,
        contact_info: String,
    }

    struct Fee has copy, store, drop {
        student_id: ID,
        amount: u64,
        payment_date: u64,
    }

    public fun create_school(
        name: String,
        location: String,
        contact_info: String,
        school_type: String,
        ctx: &mut TxContext
    ): (School, SchoolCap) {
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
        };
        let cap = SchoolCap {
            id: object::new(ctx),
            school: inner_,
        };
        (school, cap)
    }

    public fun enroll_student(
        school: ID,
        name: String,
        age: u64,
        gender: u8,
        contact_info: String,
        guardian_contact: String,
        enrollment_date: u64,
        ctx: &mut TxContext
    ): Student {
        assert!(gender == MALE || gender == FEMALE, ERROR_INVALID_GENDER);
        Student {
            id: object::new(ctx),
            school,
            name,
            age,
            gender,
            contact_info,
            guardian_contact,
            enrollment_date,
            pay: false
        }
    }

    public fun generate_fee(
        cap: &SchoolCap,
        school: &mut School,
        student_id: ID,
        amount: u64,
        due_date: u64,
        c: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(cap.school == object::id(school), ERROR_INVALID_ACCESS);
        let fee = Fee {
            student_id,
            amount,
            payment_date: timestamp_ms(c) + due_date,
        };
        table::add(&mut school.fees, sender(ctx), fee);
    }

    public fun pay_fee(
        school: &mut School,
        student: &mut Student,
        coin: Coin<SUI>,
        c: &Clock,
        ctx: &mut TxContext
    ) {
        let fee = table::remove(&mut school.fees, sender(ctx));
        assert!(coin::value(&coin) >= fee.amount, ERROR_INSUFFICIENT_FUNDS);
        assert!(fee.payment_date >= timestamp_ms(c), ERROR_INVALID_TIME);
        let balance_ = coin::into_balance(coin);
        balance::join(&mut school.balance, balance_);
        student.pay = true;
    }

    public fun withdraw(
        cap: &SchoolCap,
        school: &mut School,
        ctx: &mut TxContext
    ): Coin<SUI> {
        assert!(cap.school == object::id(school), ERROR_INVALID_ACCESS);
        let balance_ = balance::withdraw_all(&mut school.balance);
        let coin_ = coin::from_balance(balance_, ctx);
        coin_
    }

    public fun add_subject(
        school: ID,
        name: String,
        lecturer: Option<address>,
        ctx: &mut TxContext
    ): Subject {
        let subject_id = object::new(ctx);
        Subject {
            id: subject_id,
            school,
            name,
            lecturer,
        }
    }

    public fun assign_lecturer_to_subject(
        subject: &mut Subject,
        lecturer: address,
        ctx: &mut TxContext
    ) {
        subject.lecturer = some(lecturer);
    }

    public fun add_lecturer(
        school: ID,
        name: String,
        contact_info: String,
        ctx: &mut TxContext
    ): Lecturer {
        let lecturer_id = object::new(ctx);
        Lecturer {
            id: lecturer_id,
            school,
            name,
            contact_info,
        }
    }

    // =================== Public view functions ===================
    public fun get_school_balance(school: &School): u64 {
        balance::value(&school.balance)
    }

    public fun get_student_status(student: &Student): bool {
        student.pay
    }

    public fun get_fee_amount(school: &School, ctx: &mut TxContext): u64 {
        let fee = table::borrow(&school.fees, sender(ctx));
        fee.amount
    }

    // =================== CRUD Operations ===================
    public fun update_student_info(
        student: &mut Student,
        name: String,
        age: u64,
        gender: u8,
        contact_info: String,
        guardian_contact: String,
        ctx: &mut TxContext
    ) {
        assert!(gender == MALE || gender == FEMALE, ERROR_INVALID_GENDER);
        student.name = name;
        student.age = age;
        student.gender = gender;
        student.contact_info = contact_info;
        student.guardian_contact = guardian_contact;
    }

    public fun remove_student(
        cap: &SchoolCap,
        school: &mut School,
        student_id: ID,
        ctx: &mut TxContext
    ) {
        assert!(cap.school == object::id(school), ERROR_INVALID_ACCESS);
        let fee = table::remove(&mut school.fees, sender(ctx));
        assert!(fee.student_id == student_id, ERROR_NOT_FOUND);
    }

    public fun add_funds_to_school(
        school: &mut School,
        amount: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        let added_balance = coin::into_balance(amount);
        balance::join(&mut school.balance, added_balance);
    }

    public fun refund_funds_from_school(
        school: &mut School,
        amount: u64,
        ctx: &mut TxContext
    ): Coin<SUI> {
        let balance_value = balance::value(&school.balance);
        assert!(balance_value >= amount, ERROR_INSUFFICIENT_FUNDS);
        let coin_ = coin::take(&mut school.balance, amount, ctx);
        coin_
    }

    public fun update_subject_info(
        subject: &mut Subject,
        name: String,
        lecturer: Option<address>,
        ctx: &mut TxContext
    ) {
        subject.name = name;
        subject.lecturer = lecturer;
    }

    public fun update_lecturer_info(
        lecturer: &mut Lecturer,
        name: String,
        contact_info: String,
        ctx: &mut TxContext
    ) {
        lecturer.name = name;
        lecturer.contact_info = contact_info;
    }

    public fun get_student_details(
        student: &Student
    ): (String, u64, u8, String, String, u64, bool) {
        (
            student.name,
            student.age,
            student.gender,
            student.contact_info,
            student.guardian_contact,
            student.enrollment_date,
            student.pay
        )
    }

    public fun get_lecturer_details(
        lecturer: &Lecturer
    ): (String, String) {
        (
            lecturer.name,
            lecturer.contact_info
        )
    }

    public fun get_subject_details(
        subject: &Subject
    ): (String, Option<address>) {
        (
            subject.name,
            subject.lecturer
        )
    }
}
