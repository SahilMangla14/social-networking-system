import requests 
url  = "http://localhost:8000/create-user"
data = [
  {
    "first_name": "John",
    "middle_name": "A",
    "last_name": "Doe",
    "mobile_number": "1234567890",
    "email": "john.doe@example.com",
    "password": "password123",
    "bio": "A software engineer."
  },
  {
    "first_name": "Jane",
    "middle_name": "B",
    "last_name": "Smith",
    "mobile_number": "9876543210",
    "email": "jane.smith@example.com",
    "password": "securepass",
    "bio": "A marketing specialist."
  },
  {
    "first_name": "Alice",
    "middle_name": "M",
    "last_name": "Johnson",
    "mobile_number": "5551234567",
    "email": "alice.johnson@example.com",
    "password": "pass123",
    "bio": "An aspiring artist."
  },
  {
    "first_name": "Bob",
    "middle_name": "C",
    "last_name": "Williams",
    "mobile_number": "3335557777",
    "email": "bob.williams@example.com",
    "password": "bobpass",
    "bio": "A data analyst."
  },
  {
    "first_name": "Eva",
    "middle_name": "R",
    "last_name": "Miller",
    "mobile_number": "8889990000",
    "email": "eva.miller@example.com",
    "password": "evapassword",
    "bio": "A graphic designer."
  },
  {
    "first_name": "Michael",
    "middle_name": "J",
    "last_name": "Davis",
    "mobile_number": "4442221111",
    "email": "michael.davis@example.com",
    "password": "miked123",
    "bio": "A project manager."
  },
  {
    "first_name": "Sophia",
    "middle_name": "L",
    "last_name": "Taylor",
    "mobile_number": "5556667788",
    "email": "sophia.taylor@example.com",
    "password": "sophiapass",
    "bio": "A teacher and artist."
  },
  {
    "first_name": "Matthew",
    "middle_name": "S",
    "last_name": "Anderson",
    "mobile_number": "2224446666",
    "email": "matthew.anderson@example.com",
    "password": "math123",
    "bio": "A software developer."
  },
  {
    "first_name": "Olivia",
    "middle_name": "K",
    "last_name": "Clark",
    "mobile_number": "7778889999",
    "email": "olivia.clark@example.com",
    "password": "olivia_pass",
    "bio": "A biologist."
  },
  {
    "first_name": "Daniel",
    "middle_name": "P",
    "last_name": "Brown",
    "mobile_number": "3337778888",
    "email": "daniel.brown@example.com",
    "password": "daniel_pass",
    "bio": "A financial analyst."
  },
  {
    "first_name": "Ava",
    "middle_name": "N",
    "last_name": "Thomas",
    "mobile_number": "9998887777",
    "email": "ava.thomas@example.com",
    "password": "avapass",
    "bio": "A journalist."
  },
  {
    "first_name": "William",
    "middle_name": "H",
    "last_name": "White",
    "mobile_number": "6661112222",
    "email": "william.white@example.com",
    "password": "willpass",
    "bio": "A civil engineer."
  },
  {
    "first_name": "Mia",
    "middle_name": "G",
    "last_name": "Martinez",
    "mobile_number": "1115553333",
    "email": "mia.martinez@example.com",
    "password": "miapassword",
    "bio": "A veterinarian."
  },
  {
    "first_name": "James",
    "middle_name": "E",
    "last_name": "Harris",
    "mobile_number": "5550004444",
    "email": "james.harris@example.com",
    "password": "jamespass",
    "bio": "A lawyer."
  },
  {
    "first_name": "Emma",
    "middle_name": "F",
    "last_name": "Jackson",
    "mobile_number": "3337770000",
    "email": "emma.jackson@example.com",
    "password": "emma_pass",
    "bio": "An architect."
  },
  {
    "first_name": "Benjamin",
    "middle_name": "I",
    "last_name": "Young",
    "mobile_number": "8882225555",
    "email": "benjamin.young@example.com",
    "password": "benjaminpass",
    "bio": "A psychologist."
  },
  {
    "first_name": "Avery",
    "middle_name": "R",
    "last_name": "Moore",
    "mobile_number": "4446669999",
    "email": "avery.moore@example.com",
    "password": "avery_pass",
    "bio": "A librarian."
  },
  {
    "first_name": "Logan",
    "middle_name": "S",
    "last_name": "Cooper",
    "mobile_number": "9993331111",
    "email": "logan.cooper@example.com",
    "password": "loganpass",
    "bio": "A musician."
  },
  {
    "first_name": "Grace",
    "middle_name": "J",
    "last_name": "Lee",
    "mobile_number": "6663330000",
    "email": "grace.lee@example.com",
    "password": "gracepass",
    "bio": "A nurse."
  },
  {
    "first_name": "Elijah",
    "middle_name": "W",
    "last_name": "Ward",
    "mobile_number": "1114446666",
    "email": "elijah.ward@example.com",
    "password": "elijah_pass",
    "bio": "A chef."
  }
]


def make_post_request(url, request_body):
    try:
        # Making a POST request with the provided URL and request body
        response = requests.post(url, json=request_body)

        # Checking if the request was successful (status code 2xx)
        if response.ok:
            print("POST request successful!")
            print("Response:")
            print(response.text)
        else:
            print(f"POST request failed with status code: {response.status_code}")
            print("Response:")
            print(response.text)

    except requests.exceptions.RequestException as e:
        print(f"Error making POST request: {e}")
        
def seed_data():
    for user in data:
            make_post_request(url, user)


    
