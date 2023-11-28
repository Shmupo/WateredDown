using Godot;
using System;
using System.Threading.Tasks;
using System.Collections.Generic;

using PS = Godot.PhysicsServer2D;
using RS = Godot.RenderingServer;

using Vector2 = Godot.Vector2;

using WaterParticle;
using SPHaddon;

// Basic water physics implementation controlled by the Godot physics engine

public partial class SimpleWater : Node2D
{
    [Export]
    // size is (8, 8)
	Texture2D waterParticleImage;

    [Signal]
    public delegate void ParticleCollisionEventHandler();

    List<Tuple<Rid, Rid>> particles;
    
    List<int> particlesToRemove = new List<int>();

    public ParticleSimulation SPHEngine;

    List<Particle> sharedData = new List<Particle>();

    Task[] tasks = new Task[2];

    // water particle clipping shape, not used here
    Vector2[] waterClip = new Vector2[8]
    {
        new Vector2(0, -5),
        new Vector2(-4, -4),
        new Vector2(-5, 0),
        new Vector2(-4, 4),
        new Vector2(0, 5),
        new Vector2(4, 4),
        new Vector2(5, 0),
        new Vector2(4, -4)
    };

    public override void _Ready()
    {
        SPHEngine = new ParticleSimulation();

        particles = new List<Tuple<Rid, Rid>>();

        sharedData = new List<Particle>();

        SPHEngine.Start();

        // Testing FPS
        //SpawnRandParticles(1000);
    }

    public override void _PhysicsProcess(double delta)
    {
        Tuple<Vector2, Vector2>[] result = getParticleData();

        // update values that will be passed to the SPH engine
        Task task1 = Task.Run(() => UpdateSharedData(result));

        // update visual position of particles, may be 1 frame behind physical position
        foreach (Tuple<Rid, Rid> pair in particles)
        {
            Transform2D trans = (Transform2D)PS.BodyGetState(pair.Item1, PS.BodyState.Transform);
            trans.Origin = trans.Origin - GlobalPosition;
            RS.CanvasItemSetTransform(pair.Item2, trans);

            // cehck if particle is out of screen, if so, queue to remove
            // out of screen bounds, with a 10 pixel buffer added
            if (trans.Origin.X < -10 || trans.Origin.X > 1930 || trans.Origin.Y < -10)
            {
                particlesToRemove.Add(particles.IndexOf(pair));
            }
        }

        task1.Wait();

        Task task2 = Task.Run(() => SPHEngine.SPHTask(sharedData));

        //if (sharedData.Count > 0) GD.Print(sharedData[0].Density);

        HandleCollisions();

        task2.Wait();

        ApplySPHForces();

        // removes particles listed to be removed, if any
        FreeParticles();
    }

    public override void _Process(double delta)
    {
        spawnAtClick();
        //GD.Print(particles.Count);
    }

    public override void _ExitTree()
    {
        SetPhysicsProcess(false);
        Task.WaitAll();

        // remove all particles from PhysicsServer
    // Reverse iterate to safely remove elements
    for (int i = particles.Count - 1; i >= 0; i--)
    {
        var pair = particles[i];
        PS.FreeRid(pair.Item1);
        RS.FreeRid(pair.Item2);
        particles.RemoveAt(i);
    }
    }

    public void SetModifiers(float pressMod, float viscMod)
    {
        SPHEngine.pressureModifier *= pressMod;
        SPHEngine.viscosityModifier *= viscMod;
    }

    // spawn random particles
    public void SpawnRandParticles(int amount)
	{
		for (int i = 0; i < amount; i++)
		{
			Random random = new Random();
			Vector2 pos = new Vector2(random.Next(0, 800), random.Next(0, 300));
			Vector2 vel = new Vector2(random.Next(-100, 100), random.Next(-5, 5));

			CreateParticle(pos, vel);
		}
	}

    // fires a blob of particles at a position at the specified velocity
	public void FireBlob(int amount, Vector2 initPos, Vector2 vel)
	{
		for (int i = 0; i < amount; i++)
		{
			Random random = new Random();
			initPos += new Vector2(random.Next(-8, 8), random.Next(-8, 8));

			CreateParticle(initPos, vel);
		}
	}

    private void spawnAtClick()
    {
        if (Input.IsActionPressed("click"))
        {
            CreateParticle(GetGlobalMousePosition(), new Vector2(0.0f, 0.0f));
        }
    }

    private void CreateParticle(Vector2 pos, Vector2 vel)
    {
        Rid circleBody = PS.BodyCreate();
        PS.BodySetMode(circleBody, PS.BodyMode.Rigid);
        PS.BodySetSpace(circleBody, GetWorld2D().Space);

        Transform2D trans = Transform2D.Identity;
        trans.Origin = Vector2.Zero; // Assuming the physics body origin is at the center

        // Adding polygon shape to body
        Rid circle = PS.CircleShapeCreate();
        PS.ShapeSetData(circle, 3);
        PS.BodyAddShape(circleBody, circle, trans);

        // Configuring body settings
        PS.BodySetCollisionLayer(circleBody, 2);
        PS.BodySetCollisionMask(circleBody, 2 | 3);
        PS.BodySetParam(circleBody, PS.BodyParameter.Friction, 0.05f);
        PS.BodySetParam(circleBody, PS.BodyParameter.Mass, 0.05f);
        PS.BodySetParam(circleBody, PS.BodyParameter.GravityScale, 1.0f);
        PS.BodySetState(circleBody, PS.BodyState.Transform, trans);

        // currently only detects up to 5 contact points
        PS.BodySetMaxContactsReported(circleBody, 5);

        // Rendering Server
        Rid waterParticle = RS.CanvasItemCreate();
        RS.CanvasItemSetParent(waterParticle, GetCanvasItem());
        RS.CanvasItemSetTransform(waterParticle, trans);


        Rect2 rect = new Rect2
        {
            Position = new Vector2(-6, -6),
            Size = new Vector2(12, 12)
        };

        RS.CanvasItemAddTextureRect(waterParticle, rect, waterParticleImage.GetRid());
        //RS.CanvasItemSetMaterial(waterParticle, waterShader.GetRid());

        // Set the position of the physics body based on the spawn position
        trans.Origin = pos;
        PS.BodySetState(circleBody, PS.BodyState.Transform, trans);

        PS.BodySetAxisVelocity(circleBody, vel);

        Tuple<Rid, Rid> tuple = new Tuple<Rid, Rid>(circleBody, waterParticle);
    
        // storing RID and Particle object
        particles.Add(tuple);
        Particle p = new Particle();
        sharedData.Add(p);
    }

    // emit signal for terrain.gd to handle water absorbtion
    private void HandleCollisions()
    {
        for (int i = 0; i < particles.Count; i++)
        {
            PhysicsDirectBodyState2D bodyState = PS.BodyGetDirectState(particles[i].Item1);

            for (int x = 0; x < bodyState.GetContactCount(); x++)
            {
                GodotObject obj = bodyState.GetContactColliderObject(x);

                if (obj is StaticBody2D)
                {
                    StaticBody2D body = (StaticBody2D)obj;

                    Variant[] args = new Variant[] { bodyState.Transform.Origin, body };
                    EmitSignal("ParticleCollision", args);

                    // queue particle for removal only once
                    if (!particlesToRemove.Contains(i)) particlesToRemove.Add(i);
                }
            }
        }
    }

    // safetly removes particles from servers and list
    // only function that removes particles
    private void FreeParticles()
    {
        particlesToRemove.Sort();

        for (int i = particlesToRemove.Count - 1; i >= 0; i--)
        {
            // free physics and visual object in godot
            PS.FreeRid(particles[particlesToRemove[i]].Item1);
            RS.FreeRid(particles[particlesToRemove[i]].Item2);
            
            // remove from objects
            particles.RemoveAt(particlesToRemove[i]);
            sharedData.RemoveAt(particlesToRemove[i]);
        }

        particlesToRemove.Clear();
    }

    // SPH SECTION ---------------------------------

    private Tuple<Vector2, Vector2>[] getParticleData()
    {
        Tuple<Vector2, Vector2>[] output = new Tuple<Vector2, Vector2>[particles.Count];

        for (int i = 0; i < particles.Count; i++)
        {
            PhysicsDirectBodyState2D state = PS.BodyGetDirectState(particles[i].Item1);
            
            output[i] = new Tuple<Vector2, Vector2>(state.Transform.Origin, state.LinearVelocity); 
        }

        return output;
    }

    // update position and velocity of Particle objects
    // and refreshes the spatial hash grid
    private void UpdateSharedData(Tuple<Vector2, Vector2>[] pair) 
    {
        SPHEngine.grid.grid.Clear();

        for (int i = 0; i < pair.Length; i++)
        {
            Particle p = sharedData[i];

            p.Position = pair[i].Item1;
            p.Velocity = pair[i].Item2;

            SPHEngine.grid.Insert(p);
        }
    }

    private void ApplySPHForces() 
    {
        for (int i = 0; i < sharedData.Count; i++)
        {
            Vector2 force = sharedData[i].Force;
            PS.BodyApplyForce(particles[i].Item1, force);
            //GD.Print("Applied", force);
        }
    }
}
