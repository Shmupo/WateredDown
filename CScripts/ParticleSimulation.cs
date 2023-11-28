using Godot;
using System;
using System.Collections.Generic;

using Vector2 = Godot.Vector2;

using SpatialHashGrid;
using WaterParticle;

namespace SPHaddon
{
	public partial class ParticleSimulation : Node2D
	{
		[Export]
		Texture2D waterParticleImage;

		// SIMULATION CONSTANTS
		const float particleMass = 2.5f;
		const float particleRadius = 3.0f;
		
		public float pressureModifier = 300f; 
		public float viscosityModifier = 20.0f; // 10 gets 1/10 of neighboring particle velocity

		public SpatialGrid grid;
		// size of each cell in the spatial grid
		float cellSize = 25; // 30 gets around 15 max neighbor count

		// ---------- GODOT METHODS --------------------

		// initializing variables
		public void Start()
		{
			grid = new SpatialGrid(cellSize);
		}

		public void PrintModifiers()
		{
			GD.Print("Viscosity at " + viscosityModifier);
			GD.Print("Pressure at " + pressureModifier);
		}

		// objects should be garbage collected after references are gone
		public override void _ExitTree()
		{
			grid = null;
		}

		// SPH calculation from list of particles
		public void SPHTask(List<Particle> particles)
		{
			if(particles.Count > 0) {
				Vector2 currentGridCell = grid.GetCell(particles[0]);
				List<Particle> neighbors = grid.GetParticlesInNeighboringCells(particles[0]);

				// Density / Pressure Calculations
				foreach (Particle p in particles) {
					// assign neighbors. only change neighbors if grid cell changes
					if(currentGridCell != grid.GetCell(p))
					{
						currentGridCell = grid.GetCell(p);
						neighbors = grid.GetParticlesInNeighboringCells(p);
					}

					p.Neighbors = neighbors;

					//GD.Print(neighbors.Count);

					float density = 0.0f;

					foreach (Particle n in neighbors)
					{
						if (p == n) continue;
						// density Calculation

						float distanceSqrd = p.Position.DistanceSquaredTo(n.Position);

						if (distanceSqrd > 0.5)
							density += particleMass / distanceSqrd;
					}

					p.Density = density;
				}

				// Pressure Force / Viscosity Calculation		
				foreach (Particle p in particles)
				{
					Vector2 pressure = Vector2.Zero;
					Vector2 visc = Vector2.Zero;

					float particleDensitySquared = p.Density * p.Density;

					//GD.Print(particleDensitySquared);
					
					neighbors = p.Neighbors;

					Vector2 force = Vector2.Zero;
					Vector2 viscosityForce = Vector2.Zero;

					foreach (Particle n in neighbors)
					{
						if (p == n) continue;

						Vector2 direction = (n.Position - p.Position).Normalized();
						float distanceSqrd = p.Position.DistanceSquaredTo(n.Position);
						float densityDifference = p.Density - n.Density;

						if (distanceSqrd > 0.5)
						{
							force += direction * pressureModifier * (densityDifference / distanceSqrd);

							// adding portion of neighbor velocity to particle velocity
							viscosityForce += densityDifference * (n.Velocity - p.Velocity) / viscosityModifier / distanceSqrd;
						}
						
						//if (viscosityForce.Length() > 50) GD.Print(viscosityForce, " ", densityDifference, " ", distanceSqrd);
						//if(float.IsNaN(viscosityForce.X)) GD.Print("Error, viscosity is NaN"); 
					}

					p.Force = force + viscosityForce;

					//if (force.Length() > 20.0) GD.Print(force, " ", p.Density, " ");
					//GD.Print(force);
				}
			}
		}

		// Kernel by Müller et al.
		private float StdKernel(float distanceSquared)
		{
			// Doyub Kim
			float x = 1.0f - distanceSquared / Mathf.Pow(particleRadius,2);
			return (float)(315f / ( 64f * Math.PI * Math.Pow(particleRadius,3) ) * x * x * x);
		} 
	}
}
