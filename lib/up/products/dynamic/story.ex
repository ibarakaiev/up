defmodule Up.Products.Dynamic.Story do
  @moduledoc false
  use Ash.Resource,
    otp_app: :up,
    domain: Up.Products,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshStateMachine],
    notifiers: [Ash.Notifier.PubSub]

  alias __MODULE__
  alias __MODULE__.Actions

  postgres do
    table "stories"
    repo Up.Repo
  end

  state_machine do
    initial_states [:initialized]
    default_initial_state :initialized

    transitions do
      transition :mark_as_frames_generated, from: :initialized, to: :frames_generated
    end
  end

  code_interface do
    domain Up.Products

    define :create, action: :create
    define :create_with_description, action: :create_with_description
    define :read_all, action: :read
    define :get_by_id, action: :by_id, args: [:id]
    define :get_by_hash, action: :by_hash, args: [:hash]
    define :update, action: :update
    define :generate_frames, action: :generate_frames
    define :mark_as_frames_generated, action: :mark_as_frames_generated
  end

  actions do
    defaults [:read, :destroy, create: :*, update: :*]

    create :create_with_description do
      accept [:hash, :person_one_description, :person_two_description, :couple_image_url]

      change after_transaction(fn
               changeset, {:ok, story}, _context ->
                 Story.generate_frames(story)
             end)
    end

    read :by_id do
      argument :id, :uuid, allow_nil?: false

      get? true

      filter expr(id == ^arg(:id))
    end

    read :by_hash do
      argument :hash, :string, allow_nil?: false

      get? true

      filter expr(hash == ^arg(:hash))
    end

    update :collect_image do
      require_atomic? false

      argument :couple_image_url, :string, allow_nil?: false

      change atomic_update(:couple_image_url, expr(^arg(:couple_image_url)))
    end

    update :generate_frames do
      manual Actions.GenerateFrames
    end

    update :mark_as_frames_generated do
      transition_state(:frames_generated)
    end
  end

  pub_sub do
    module UpWeb.Endpoint

    prefix "story"

    publish_all :update, ["updated", :id]
  end

  preparations do
    prepare build(load: [:frames])
  end

  attributes do
    uuid_primary_key :id

    attribute :hash, :string,
      allow_nil?: false,
      default: fn -> Up.Utils.random_string(12) end,
      public?: true

    attribute :couple_image_url, :string, public?: true
    attribute :person_one_description, :string, public?: true
    attribute :person_two_description, :string, public?: true
  end

  relationships do
    has_many :frames, __MODULE__.Frame
  end

  def prompts do
    [
      "A beautifully lit church wedding scene features PERSON ONE and PERSON TWO standing at the altar, holding hands. PERSON ONE is dressed in an elegant white wedding gown with a flowing skirt, a fitted bodice, and a delicate veil draping over their hair. PERSON TWO is wearing a classic black tuxedo with a white dress shirt, black tie, and polished dress shoes. Behind them, a priest in a dark robe with a white stole stands in front of a wooden altar adorned with soft pink flowers. The church interior has warm wooden walls, a large stained-glass window casting colorful light, and multiple candle sconces illuminating the space. Wedding guests in vintage attire, including a man with suspenders and a hat-wearing attendee, are seated in wooden pews, watching the ceremony. A rich red carpet runs down the aisle, leading to the couple at the altar.",
      "A warmly lit church wedding scene features PERSON ONE and PERSON TWO sharing a kiss. PERSON ONE is dressed in a flowing white wedding gown with a fitted bodice and a delicate veil draping over their head. PERSON TWO is wearing a formal black tuxedo with a white dress shirt. PERSON TWO is dipping PERSON ONE slightly backward while holding them close. The background showcases a wooden altar covered with a lace-trimmed cloth, with a vase filled with pink roses placed at the center. Two tall, lit candles in elegant holders stand on either side of the flowers. A stained-glass window with a circular design casts soft, colorful light into the room. The setting exudes a warm, romantic ambiance, highlighting the intimacy of the moment.",
      "A charming yet whimsical scene features PERSON ONE and PERSON TWO in front of an old, rickety house with a steeply pitched roof, peeling paint, and boarded-up windows. The house, surrounded by overgrown grass and trees with golden autumn leaves, has a rustic and weathered appearance. A \"For Sale\" sign now marked \"SOLD\" stands in the yard, slightly tilted. In the foreground, PERSON TWO, dressed in a black tuxedo with a white dress shirt, is carrying PERSON ONE in their arms. PERSON ONE is wearing a flowing white wedding dress. The couple stands on a worn pathway leading to the house, with a broken wooden fence nearby. The warm sunlight filters through the trees, casting a golden glow over the scene, creating a contrast between the couple’s joyous moment and the dilapidated yet hopeful state of their new home.",
      "Inside an old, run-down house with cracked walls and a partially collapsed ceiling, PERSON ONE and PERSON TWO are hard at work renovating their new home. Sunlight filters through dusty windows, casting a warm glow on the wooden floors. PERSON ONE, dressed in a white wedding gown with a flowing veil, is focused on sawing a wooden plank while kneeling on a makeshift workbench, their expression showing determination as they put effort into cutting the wood. Meanwhile, PERSON TWO, dressed in a black tuxedo with a white dress shirt, stands on a small wooden stool, enthusiastically hammering a nail into the wall, their posture showing dedication to fixing the house. The space is filled with exposed beams, worn-down walls, and scattered renovation materials, creating a scene of effort and teamwork as the couple transforms their dilapidated house into a home.",
      "A beautifully restored and vibrant house stands proudly behind a charming white picket fence, surrounded by lush green trees under a bright blue sky. The house features a whimsical mix of colors, with a cheerful yellow front section, a soft blue side, and warm orange and pink accents. Its steeply pitched roof, adorned with dark shingles, includes a quaint dormer window, while the bright pink-framed windows add a playful touch. The front porch, with its inviting wooden door and decorative railing, exudes warmth and charm. A white mailbox stands near the entrance, complementing the neatly trimmed bushes lining the front yard. The transformation from a once-dilapidated structure to this lively and welcoming home reflects care, dedication, and the dreams built within its walls.",
      "On a bright, sunny day with fluffy white clouds drifting across a blue sky, PERSON ONE and PERSON TWO are on a lush green hillside dotted with small yellow flowers. The hill slopes gently upward, leading to a large, leafy tree that provides shade at the top. PERSON ONE, dressed in a light-colored knee-length dress, stands at the crest of the hill with hands on their hips, looking down expectantly. A small bag and a book rest beside them in the grass. Meanwhile, PERSON TWO, wearing a brown jacket and pants, is eagerly climbing up the hill, reaching toward PERSON ONE with excitement and determination. In the background, rooftops and church spires peek out from behind trees, suggesting a quaint town nestled in the valley below. The scene radiates warmth, playfulness, and a sense of adventure as the two share a special moment in their favorite spot.",
      "On a warm, sunny day, PERSON ONE and PERSON TWO lay side by side on a soft, checkered picnic blanket spread over lush green grass, surrounded by scattered yellow flowers. PERSON ONE, dressed in a light yellow gingham dress, points excitedly toward the sky while holding hands with PERSON TWO, who is dressed in a mustard-colored blazer, white shirt, and blue tie. Their expressions reflect joy and wonder as they gaze up at the clouds. Nearby, a picnic basket filled with fresh bread, fruit, and a bottle rests on the grass, along with a vintage camera. The sunlight filters through the tree branches above, casting dappled shadows on the scene, creating a moment of pure serenity and shared imagination.",
      "A young couple, PERSON ONE and PERSON TWO, are lying on a checkered picnic blanket on a lush green lawn, gazing at the sky. PERSON ONE is wearing a yellow gingham dress with thin straps and a small bow at the shoulder. Their brown hair is styled short and slightly wavy. They are animatedly pointing toward the sky, expressing excitement and wonder. PERSON TWO is dressed in a mustard-yellow suit jacket, a white dress shirt, and a blue tie. They have neatly combed brown hair and are wearing thick black glasses. Their hands are resting on their chest, and they have a peaceful and content expression. Sunlight filters through the trees, casting dappled shadows on them and the grass, creating a warm, nostalgic atmosphere.",
      "A cozy living room scene featuring PERSON ONE and PERSON TWO, both engrossed in reading. PERSON ONE is seated in a patterned armchair with curved armrests, wearing a pink and purple floral blouse, purple pants, and brown shoes. Their brown hair is neatly styled with a pink headband. They are holding a small book, reading with a gentle smile. PERSON TWO is seated in a plush red armchair, wearing a cream-colored suit, a yellow vest, a white dress shirt, and a blue tie. They have neatly combed brown hair and are wearing thick black glasses. They are holding an open blue book and lightly holding PERSON ONE's hand. The room is warmly lit with vintage decor, including a wooden side table with a lamp and a teacup, a window with golden curtains, and a wooden shelf with small decorative items in the background. A round, woven rug covers the floor, enhancing the warm and nostalgic atmosphere.",
      "Cloudgazing and pointing again",
      "A vast blue sky stretches endlessly, dotted with soft, wispy clouds. Among them, a distinct cloud formation takes shape, resembling a playful, fluffy baby. The cloud's gentle contours and bright white hues stand out against the sky blue background, evoking a sense of whimsy and imagination.",
      "A serene outdoor scene featuring PERSON ONE and PERSON TWO lying on a checkered picnic blanket spread over a lush green lawn. PERSON ONE is wearing a pink, sleeveless, buttoned dress with a fitted waist and a delicate floral pattern. Their brown hair is neatly styled, and they are resting on one arm while gazing at PERSON TWO with admiration. PERSON TWO is dressed in a black suit jacket over a light blue dress shirt, with a white undershirt and beige pants. They have neatly combed brown hair and are wearing thick black glasses. They are pointing towards the sky with an excited expression as if spotting something intriguing. A vintage camera sits beside them on the blanket. Sunlight filters through the leaves, casting warm shadows on the grass, creating a nostalgic and peaceful atmosphere.",
      "A warmly lit nursery in progress, where PERSON ONE and PERSON TWO are preparing for a baby. The walls are painted soft yellow, and a large, colorful mural featuring a blue sky, fluffy clouds, a bright sun, and a stork carrying a bundle is being painted on one side of the room. PERSON ONE is standing barefoot on a wooden ladder, wearing rolled-up jeans, a white blouse, and a pink headscarf, carefully adding details to the mural with a paintbrush. PERSON TWO, dressed in a white button-up shirt, beige pants, and thick black glasses, is adjusting a mobile above a white crib with spindled bars. The mobile consists of small airships and airplanes. Sheets of paper with sketches are scattered on the wooden floor. Sunlight streams in through a window, highlighting the joy and excitement in the room as the couple prepares for their new arrival.",
      "PERSON 1 is holding their new born baby for the first time, looking at the crying face with motherly love. PERSON 2 looks on with awe.",
      "PERSON 1 gives PERSON 2 their newborn baby to hold, and they look at each other and smile warmly.",
      "A peaceful indoor scene where PERSON ONE is painting a dreamlike mural on a large canvas or wall. They are wearing a white long-sleeved shirt with rolled-up sleeves, splattered with paint, and a deep pink headscarf covering their hair. Their arm is extended as they carefully add details to the painting with a brush. The artwork depicts a whimsical house with a blue roof and colorful walls perched atop a towering, narrow rock formation, surrounded by deep blue cliffs with dramatic textures. The background of the painting is a soft gradient of sky blue and white, creating a surreal atmosphere. The room has warm, vintage wallpaper with floral patterns, and a guitar leans against the wall nearby, hinting at a creative and artistic space. The lighting is soft and natural, adding a cozy, intimate feel to the moment.",
      "A cozy living room scene where PERSON ONE and PERSON TWO are standing near a small wooden table with a glass jar labeled \"Paradise Falls.\" The jar contains a few coins and dollar bills, symbolizing their dream of saving for a future adventure. PERSON ONE is wearing a long-sleeved button-up shirt with paint splatters, high-waisted jeans, and a black belt, with a pink headscarf tied around their head. They are standing with one hand on their hip and the other gesturing playfully, looking at PERSON TWO with a warm and hopeful expression. PERSON TWO is dressed in a short-sleeved white button-up shirt tucked into brown pants, with a brown belt. They are facing PERSON ONE, appearing to listen attentively. In the background, a large painting of a house perched on towering cliffs is displayed above a fireplace, and various musical instruments, picture frames, and vintage furniture pieces decorate the warmly lit room, adding to its nostalgic and homey atmosphere.",
      "A quiet outdoor scene featuring PERSON TWO crouching beside an old red vintage car, examining the flat front tire with concern. They are wearing a short-sleeved white button-up shirt, beige pants, a brown belt, and black shoes. The car’s metal hubcap reflects their face, creating a distorted but clear image of their expression. The car has visible dust and wear, indicating age and frequent use. The surrounding environment is sunlit, with an open road and greenery in the background, hinting at a rural or suburban setting. The mood conveys a moment of unexpected trouble, as if life’s small inconveniences have momentarily interrupted their journey.",
      "A tense and emotional moment in a cozy living room where PERSON ONE and PERSON TWO are standing near a small wooden table. On the table, a shattered glass jar labeled \"Paradise Falls\" lies broken, with scattered coins and torn dollar bills spilling out. PERSON ONE is wearing a pale green, sleeveless dress with a delicate floral pattern and a green belt. Their brown hair is pulled back, and they have a pained expression, eyes closed and arms slightly tensed, as if trying to contain their emotions. PERSON TWO is dressed in a mustard-colored suit jacket, a white dress shirt, and an orange vest with a black tie. Their face is tense and frustrated, their fist still clenched from the motion of breaking the jar. The background showcases a warm, nostalgic home setting with wooden shelves, a fireplace, and a large painting of a house on a towering rock formation. The atmosphere is filled with the light-hearted and subtle disappointment of an unexpected financial need has forced them to dip into their dream savings.",
      "A nostalgic and heartfelt scene featuring a large glass jar labeled \"Paradise Falls,\" placed on a small wooden table in a cozy, warmly lit room. The label is taped onto the jar with four pieces of aged tape, and inside, a few coins and dollar bills can be seen, symbolizing a dream savings fund. In the foreground, PERSON ONE is partially visible, wearing a colorful sleeveless dress with a bold geometric pattern and a purple belt. They are reaching toward the jar with a delicate hand, gently placing or retrieving money. The background features wooden furniture, including a vintage dresser with round drawer handles, a framed abstract artwork, and a dark blue lamp with a classic design. Shelves above hold small decorative items, reinforcing the warm, nostalgic atmosphere of a home built with love and shared dreams.",
      "A heartwarming scene unfolds in a cozy, warmly lit living room where PERSON ONE and PERSON TWO excitedly surprise their 12 year old boy with a brand-new computer for their birthday. The room is filled with nostalgic charm—vintage furniture, a well-worn but beloved rug, and shelves lined with keepsakes from years past. At the center of the scene, a sleek, futuristic gaming PC sits on a wooden table, its transparent side panel revealing a powerful GPU with dazzling RGB lighting that cycles through vibrant colors. The teenager, eyes wide with astonishment and joy, reaches out to touch the glowing machine, their reflection shimmering on the tempered glass. PERSON ONE, wearing a comfortable yet stylish outfit, leans forward with a warm smile, while PERSON TWO, dressed in a classic but slightly formal look, stands with arms crossed, proud of this long-awaited gift. Nearby, the remnants of a birthday celebration—wrapping paper, balloons, and a partially eaten cake—add to the festive atmosphere, marking a milestone moment where years of hard work and savings turn into an unforgettable memory.",
      "PERSON 2 has to break the money jar again.",
      "In a warmly lit home filled with nostalgia and love, PERSON TWO stands in front of a mirror, adjusting a brand-new, sleek tie with a proud yet slightly nervous smile. Dressed in a crisp, well-fitted suit, they hold a polished leather briefcase in one hand—a symbol of their long-awaited promotion. Behind them, PERSON ONE watches with admiration, a joyful expression on their face as they straighten PERSON TWO’s collar, sharing in the pride of this achievement. The living room is decorated with warm, vintage furnishings, and on a nearby table, a small celebration setup is visible—a congratulatory card, a neatly wrapped gift, and a bottle of sparkling cider, all hinting at the excitement of this career milestone. Sunlight streams through the window, casting a golden glow on the scene, highlighting the journey of dedication and perseverance that has led to this moment of success.",
      "A scene features PERSON ONE and PERSON TWO in a warmly lit indoor setting. PERSON ONE is wearing an olive-green scout-style uniform with a badge on the sleeve, a black belt, and a purple ribbon tying their hair. They are adjusting the tie of PERSON TWO, who is dressed in a white dress shirt, a red, white, and blue striped tie, black suspenders with brown leather attachments, and a red armband. The background consists of a cozy home interior with wooden furniture, a red armchair, and a window letting in natural daylight. The lighting is soft and warm, casting a nostalgic atmosphere. The scene captures a moment of affection and care as PERSON ONE adjusts PERSON TWO’s tie, while PERSON TWO looks slightly reluctant but accepting."
    ]
  end

  def total_prompts do
    prompts() |> length()
  end
end
