from database import get_db

user_group_id = [
    1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,1,2,3,4,5
]

user_group_titles = [
    "Adventure Seekers",
    "Tech Enthusiasts",
    "Fitness Fanatics",
    "Book Club",
    "Movie Buffs",
    "Art Lovers",
    "Foodies",
    "Gaming Geeks",
    "Music Mania",
    "Travel Explorers",
    "Coding Wizards",
    "Photography Passion",
    "Nature Admirers",
    "Science Enthusiasts",
    "Yoga and Meditation",
    "History Buffs",
    "Fashion Forward",
    "DIY Crafters",
    "Sports Fan Club",
    "Friends group"
]

user_group_summaries = [
    "A group for those seeking thrilling adventures!",
    "For all things tech-related and beyond.",
    "Get fit and healthy with like-minded individuals.",
    "Discuss and explore the world of literature.",
    "Share your favorite movies and discover new ones.",
    "Appreciate and discuss various forms of art.",
    "Connect with fellow food lovers and share recipes.",
    "For gamers who love to discuss all things gaming.",
    "Explore the world of music with fellow enthusiasts.",
    "Share travel experiences and tips.",
    "A community for coding enthusiasts and experts.",
    "Capture and share the beauty of photography.",
    "Connect with nature lovers and outdoor enthusiasts.",
    "Discuss and explore the wonders of science.",
    "Find peace and balance through yoga and meditation.",
    "Dive into the depths of history with passionate individuals.",
    "Stay updated on the latest fashion trends and styles.",
    "Engage in creative DIY projects and crafts.",
    "Cheer for your favorite sports teams with fellow fans.",
    "Cherish this friendship forever"
]



def create_user_group(created_by_user_id,title,summary):
    try:
        with get_db() as db:
            db.callproc("create_user_group", [created_by_user_id, title, summary])
            result = db.fetchone()

            response_data = {"group_id": result[0]}

            # print(response_data)
    except HTTPException as e:
        raise e  # Rethrow HTTPException with status code and details
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error calling stored procedure create_user_group: {e}",
        )


def seed_data():
    for i in range(len(user_group_id)):
        create_user_group(user_group_id[i],user_group_titles[i],user_group_summaries[i])
    print("seed user group done...")
