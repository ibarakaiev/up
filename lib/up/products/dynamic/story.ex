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
      change transition_state(:frames_generated)
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
      "A warmly lit church wedding shows PERSON ONE in an elegant white gown with a flowing skirt and veil, and PERSON TWO in a classic black tuxedo. A priest stands at the wooden altar adorned with soft pink flowers, with warm wooden walls and a stained-glass window casting colorful light. Vintage-clad guests watch from wooden pews, and a rich red carpet leads to the altar.",
      "A warmly lit church setting captures PERSON ONE and PERSON TWO sharing a kiss. PERSON ONE wears a flowing white gown with a delicate veil, while PERSON TWO wears a formal black tuxedo and dips PERSON ONE gently. Behind them, a wooden altar with a lace-trimmed cloth, pink roses, and lit candles sits beneath a circular stained-glass window.",
      "PERSON TWO, in a black tux, carries PERSON ONE, in a flowing white dress, toward a dilapidated house with peeling paint and boarded-up windows. The yard’s grass is overgrown, and a 'For Sale' sign marked 'SOLD' stands askew. Warm sunlight filters through autumn trees, contrasting the couple’s joy with the home’s worn condition.",
      "Inside a run-down house with cracked walls and a partially collapsed ceiling, PERSON ONE, still in a white wedding gown, saws a wooden plank with determination. PERSON TWO, dressed in a tux, stands on a small stool, hammering a nail. Exposed beams, worn walls, and scattered materials highlight the hard work they share in renovating.",
      "A once-dilapidated house is now vibrant and welcoming behind a white picket fence, surrounded by lush trees under a bright sky. Painted in cheerful yellows, blues, and pink accents, the steeply pitched roof and dormer window add charm. A neat porch and bright windows exude warmth and reflect the couple’s care and dedication.",
      "On a sunny day, PERSON ONE stands atop a gentle hill scattered with yellow flowers, hands on hips, while PERSON TWO climbs eagerly toward them. A leafy tree crowns the hill, offering shade. Nearby, a bag and book rest on the grass. In the distance, rooftops and spires peek out, suggesting a quaint town below.",
      "On a checkered picnic blanket, PERSON ONE wears a yellow gingham dress with a small bow and short, wavy brown hair, pointing at the sky excitedly. PERSON TWO, in a mustard-yellow suit jacket, white shirt, blue tie, and thick black glasses, rests their hands on their chest, looking peaceful. Sunlit dappled shadows add nostalgic warmth.",
      "PERSON ONE, in a patterned blouse and purple pants, sits in a curved armchair, reading with a gentle smile. PERSON TWO, in a cream suit, yellow vest, and thick glasses, reads a blue book while lightly holding PERSON ONE’s hand. A lamp-lit vintage room with wooden furniture creates a cozy, nostalgic atmosphere.",
      "PERSON ONE, in a pink floral dress, lies on a checkered blanket, smiling warmly at PERSON TWO. PERSON TWO, in a black suit jacket, light blue shirt, striped tie, and beige pants, points at the sky, speaking excitedly. A vintage camera and scattered yellow flowers set a peaceful, dreamlike mood.",
      "A vast blue sky filled with wispy clouds features one that distinctly resembles a fluffy baby. Its soft contours and bright white color stand out, evoking whimsy against the sky’s calming backdrop.",
      "PERSON ONE, in a pink sleeveless floral dress, and PERSON TWO, in a black suit jacket and beige pants, lie on a checkered blanket. PERSON TWO points skyward with excitement while PERSON ONE gazes with admiration. A vintage camera rests nearby, and soft sunlight filters through leaves, creating a nostalgic, peaceful scene.",
      "In a warm nursery, PERSON ONE stands on a ladder painting a mural of a sky with clouds and a stork on soft yellow walls. PERSON TWO, in glasses, adjusts a mobile of airships above a white crib. Sunlight streams in, highlighting sketches on the floor and the couple’s excitement for their baby.",
      "PERSON ONE cradles their newborn, gazing at the crying baby with motherly love. PERSON TWO watches in awe, overwhelmed by the touching first moments of parenthood.",
      "In an artistic, vintage-inspired room, PERSON ONE, wearing a paint-splattered shirt and pink headscarf, carefully paints a whimsical scene of a house atop a towering rock. A guitar leans against floral wallpaper, and soft natural light adds a cozy, creative atmosphere.",
      "In a cozy living room, a large jar labeled 'Paradise Falls' holds a few coins and bills. PERSON ONE, paint-splattered shirt and pink headscarf, gestures hopefully at PERSON TWO, in a short-sleeved button-up and brown pants. A painting of a cliffside house hangs above a fireplace, reflecting their shared travel dreams.",
      "PERSON TWO, in a white shirt and beige pants, crouches by an old red car with a flat tire, looking concerned. The dusty hubcap reflects their worried face. Surrounded by sunlit greenery, the scene captures life’s small setbacks interrupting their plans.",
      "In a warm living room, the shattered 'Paradise Falls' jar spills coins and torn bills. PERSON ONE, in a pale green floral dress, stands tense with eyes closed. PERSON TWO, wearing a mustard suit jacket and orange vest, clenches a fist in frustration. Their nostalgic home setting contrasts the disappointment of dipping into their dream fund.",
      "A large glass jar labeled 'Paradise Falls' sits on a small table in a cozy room. PERSON ONE, wearing a colorful sleeveless dress, delicately places money inside. Vintage furniture, a dresser with round handles, and a blue lamp create a warm, nostalgic ambiance as they nurture their shared dream.",
      "In a cozy, vintage-decorated living room, PERSON ONE and PERSON TWO present a glowing new gaming PC to their astonished 12-year-old. The child reaches out excitedly, reflected in the PC’s glass side. Remnants of a birthday celebration—balloons and half-eaten cake—mark this joyful milestone.",
      "Once again, PERSON TWO has to break the 'Paradise Falls' jar, signaling another setback. Coins and bills spill out, reflecting a difficult decision to use the long-held travel savings for urgent needs.",
      "In warm light, PERSON ONE, wearing an olive-green scout uniform with a badge and a purple hair ribbon, adjusts the red, white, and blue tie of PERSON TWO, who wears a white shirt, black suspenders, and a red armband. The cozy home interior and soft daylight set a nostalgic tone."
    ]
  end

  def total_prompts do
    prompts() |> length()
  end
end
