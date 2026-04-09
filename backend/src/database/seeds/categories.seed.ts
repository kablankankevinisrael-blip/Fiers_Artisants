import { DataSource } from 'typeorm';
import { randomUUID } from 'node:crypto';

const categories = [
  { name: 'Bâtiment & Construction', slug: 'batiment-construction', icon_url: '🧱', display_order: 1, subcategories: ['Maçon', 'Carreleur', 'Plâtrier', 'Ferblantier'] },
  { name: 'Menuiserie & Ébénisterie', slug: 'menuiserie-ebenisterie', icon_url: '🪵', display_order: 2, subcategories: ['Menuisier bois', 'Menuisier aluminium', 'Ébéniste'] },
  { name: 'Électricité', slug: 'electricite', icon_url: '⚡', display_order: 3, subcategories: ['Électricien bâtiment', 'Électricien industriel', 'Domoticien'] },
  { name: 'Plomberie', slug: 'plomberie', icon_url: '🔧', display_order: 4, subcategories: ['Plombier', 'Chauffagiste'] },
  { name: 'Peinture & Décoration', slug: 'peinture-decoration', icon_url: '🎨', display_order: 5, subcategories: ['Peintre bâtiment', 'Décorateur intérieur', 'Staffeur'] },
  { name: 'Architecture & Ingénierie', slug: 'architecture-ingenierie', icon_url: '🏗️', display_order: 6, subcategories: ['Architecte', 'Ingénieur civil', 'Géomètre'] },
  { name: 'Textile & Mode', slug: 'textile-mode', icon_url: '✂️', display_order: 7, subcategories: ['Tailleur', 'Couturier', 'Brodeur'] },
  { name: 'Métallurgie', slug: 'metallurgie', icon_url: '⚒️', display_order: 8, subcategories: ['Forgeron', 'Soudeur', 'Ferronnier d\'art'] },
  { name: 'Fleuriste & Paysagisme', slug: 'fleuriste-paysagisme', icon_url: '🌸', display_order: 9, subcategories: ['Fleuriste', 'Jardinier', 'Paysagiste'] },
  { name: 'Automobile', slug: 'automobile', icon_url: '🚗', display_order: 10, subcategories: ['Mécanicien auto', 'Électricien auto', 'Tôlier'] },
  { name: 'Services créatifs', slug: 'services-creatifs', icon_url: '📸', display_order: 11, subcategories: ['Photographe', 'Vidéaste', 'Graphiste'] },
  { name: 'Services domestiques', slug: 'services-domestiques', icon_url: '🧹', display_order: 12, subcategories: ['Agent d\'entretien', 'Femme/Homme de ménage'] },
  { name: 'Beauté & Bien-être', slug: 'beaute-bien-etre', icon_url: '💇', display_order: 13, subcategories: ['Coiffeur', 'Barbier', 'Esthéticienne'] },
  { name: 'Restauration', slug: 'restauration', icon_url: '🍳', display_order: 14, subcategories: ['Cuisinier', 'Traiteur', 'Pâtissier'] },
  { name: 'Tech & Numérique', slug: 'tech-numerique', icon_url: '🖥️', display_order: 15, subcategories: ['Réparateur téléphone', 'Informaticien', 'Installateur réseau'] },
  { name: 'Ameublement', slug: 'ameublement', icon_url: '🪑', display_order: 16, subcategories: ['Tapissier', 'Matelassier', 'Vitrier'] },
];

export async function seedCategories(dataSource: DataSource): Promise<void> {
  const categoryRepo = dataSource.getRepository('categories');
  const subcategoryRepo = dataSource.getRepository('subcategories');

  for (const cat of categories) {
    const existingCat = await categoryRepo.findOne({ where: { slug: cat.slug } });
    if (existingCat) continue;

    const categoryId = randomUUID();
    await categoryRepo.save({
      id: categoryId,
      name: cat.name,
      slug: cat.slug,
      icon_url: cat.icon_url,
      display_order: cat.display_order,
      is_active: true,
    });

    for (const subName of cat.subcategories) {
      const subSlug = subName
        .toLowerCase()
        .normalize('NFD')
        .replace(/[\u0300-\u036f]/g, '')
        .replace(/[^a-z0-9]+/g, '-')
        .replace(/(^-|-$)/g, '');

      await subcategoryRepo.save({
        id: randomUUID(),
        category_id: categoryId,
        name: subName,
        slug: subSlug,
      });
    }
  }

  console.log('✅ Categories seeded successfully');
}
