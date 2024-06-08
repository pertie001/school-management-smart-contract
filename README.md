# School Management Smart Contract Module

The School Management Smart Contract module facilitates the decentralized management of educational institutions, providing functionalities to manage schools, students, fees, subjects, and lecturers. This module leverages blockchain technology to ensure transparency, security, and efficiency in school administration processes.

## Struct Definitions

### School
- **id**: Unique identifier for each school.
- **name**: Name of the school.
- **location**: Location of the school.
- **contact_info**: Contact information for the school.
- **school_type**: Type or category of the school.
- **fees**: Table storing fees associated with students.
- **balance**: Balance of SUI tokens held by the school.
- **subjects**: Table storing subjects offered by the school.
- **lecturers**: Table storing lecturers employed by the school.

### SchoolCap
- **id**: Unique identifier for capabilities related to school management.
- **school**: ID of the associated school.

### Student
- **id**: Unique identifier for each student.
- **school**: ID of the school the student is enrolled in.
- **name**: Name of the student.
- **age**: Age of the student.
- **gender**: Gender of the student (0 for male, 1 for female).
- **contact_info**: Contact information for the student.
- **guardian_contact**: Contact information of the student's guardian.
- **enrollment_date**: Timestamp when the student was enrolled.
- **pay**: Boolean indicating if the student has paid fees.

### Subject
- **id**: Unique identifier for each subject.
- **school**: ID of the school offering the subject.
- **name**: Name of the subject.
- **lecturer**: Optional field indicating the lecturer assigned to teach the subject.

### Lecturer
- **id**: Unique identifier for each lecturer.
- **school**: ID of the school employing the lecturer.
- **name**: Name of the lecturer.
- **contact_info**: Contact information for the lecturer.

### Fee
- **student_id**: ID of the student associated with the fee.
- **amount**: Amount of fee to be paid.
- **payment_date**: Timestamp by which the fee must be paid.

## Public - Entry Functions

### create_school
Creates a new school with specified attributes such as name, location, contact information, and type.

### enroll_student
Enrolls a student into a specified school with details including name, age, gender, contact information, guardian contact, and enrollment date.

### generate_fee
Generates a fee for a student enrolled in a school, specifying the amount, due date, and associating it with the school's fee management.

### pay_fee
Allows a student to pay a specified fee to the school, verifying the payment amount and due date before updating the school's balance and marking the fee as paid for the student.

### withdraw
Enables withdrawal of funds from the school's balance, ensuring proper authorization and security checks.

### add_subject
Adds a new subject to a school's curriculum, specifying the subject name and optionally assigning a lecturer.

### assign_lecturer_to_subject
Assigns a lecturer to teach a specific subject within a school.

### add_lecturer
Adds a new lecturer to a school, specifying the lecturer's name and contact information.

## Public - View Functions

### get_school_balance
Retrieves the current balance of SUI tokens held by a school.

### get_student_status
Checks if a student has paid their fees.

### get_fee_amount
Retrieves the amount of fee due for a student enrolled in a school.

### get_student_details
Retrieves detailed information about a specific student, including name, age, gender, contact information, guardian contact, enrollment date, and fee payment status.

### get_lecturer_details
Retrieves details of a specific lecturer, including name and contact information.

### get_subject_details
Retrieves details of a specific subject offered by a school, including the subject name and assigned lecturer (if any).

## CRUD Operations

### update_student_info
Allows updating information of a specific student, including name, age, gender, contact information, and guardian contact.

### remove_student
Removes a student from a school, ensuring proper authorization and fee validation.

### add_funds_to_school
Allows adding SUI tokens to a school's balance for financial operations and management.

### refund_funds_from_school
Refunds SUI tokens from a school's balance, ensuring sufficient funds and security checks.

### update_subject_info
Allows updating information of a specific subject, including name and assigned lecturer.

### update_lecturer_info
Allows updating information of a specific lecturer, including name and contact information.

## Setup

### Prerequisites

1. **Rust and Cargo**: Install Rust and Cargo on your development machine for compiling the smart contract.

2. **SUI Blockchain**: Set up and deploy the SUI blockchain environment to interact with the smart contract.

### Build and Deploy

1. Clone the School Management Smart Contract repository and navigate to the project directory.

2. Compile the smart contract using Rust:

   ```bash
   cargo build --release
   ```

3. Deploy the compiled smart contract to your local or testnet SUI blockchain node using the appropriate deployment tools.

4. Record relevant contract addresses and identifiers for interacting with deployed contracts.

## Usage

### Creating a School

Invoke `create_school` function to create a new educational institution with details such as name, location, contact information, and type.

### Enrolling a Student

Use `enroll_student` function to enroll a student into a specified school, providing necessary student details.

### Managing Fees

Generate fees for students (`generate_fee`) and allow students to pay fees (`pay_fee`), ensuring timely and accurate financial transactions.

### Managing Subjects and Lecturers

Add subjects (`add_subject`) and assign lecturers (`assign_lecturer_to_subject`) to enrich the school's academic offerings.

### Updating Information

Update student (`update_student_info`), subject (`update_subject_info`), and lecturer (`update_lecturer_info`) information as needed to maintain accurate records.

## Conclusion

The School Management Smart Contract module provides a robust framework for decentralized administration of educational institutions. By leveraging blockchain technology, this module enhances transparency, security, and efficiency in managing schools, students, fees, subjects, and lecturers. It serves as a foundational component for implementing educational systems that prioritize accountability and accessibility while minimizing administrative overhead.