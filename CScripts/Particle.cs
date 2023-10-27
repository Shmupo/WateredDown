using System.Collections.Generic;
using Godot;

// using C# default Vector2s
using vector2 = Godot.Vector2;

namespace WaterParticle {
    public partial class Particle : GodotObject
    {
        private vector2 _velocity = new vector2(0, 0);
        public vector2 Velocity
        {
            get { return _velocity; }
            set { _velocity = value; }
        }

        // force to be applied to particle per update
        private vector2 _force = new vector2(0, 0);
        public vector2 Force
        {
            get { return _force; }
            set { _force = value; }
        }        

        // redundant variable used by separate thread since other threads cannot ready CharacterBody2D variables
        private vector2 _position = new vector2(0, 0);
        public vector2 Position
        {
            get { return _position; }
            set { _position = value; }
        }

        private float _density = 0;
        public float Density
        {
            get { return _density; }
            set { _density = value; }
        }

        private List<Particle> _neighbors = new List<Particle>();
        public List<Particle> Neighbors
        {
            get { return _neighbors; }
            set { _neighbors = value; }
        }

        public Particle() {}
    }
}
